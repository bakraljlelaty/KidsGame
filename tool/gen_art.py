#!/usr/bin/env python3
"""Generates the illustrated art set with the OpenAI Images API.

Reads OPENAI_API_KEY from the environment (never stored in the repo).
Raw generations cache in --workdir so re-runs only produce missing art;
processed assets land in assets/images/{items,milo,scenes}.

What gets generated (procedural art remains for everything else):
  * 26 content items (animals, food, vehicles, toys) — transparent PNG
  * 8 Milo poses, edited from a style-anchor image for consistency
  * 11 scene backdrops (home, six bespoke games, generic activity,
    three sticker-book scenes) — landscape JPEG

Run from the repo root:
    OPENAI_API_KEY=... python3 tool/gen_art.py --anchor path/to/milo_anchor.png
"""

import argparse
import base64
import io
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL = "gpt-image-1.5"

STYLE = (
    "Children's mobile game illustration, flat vector style with soft "
    "gradient shading, thick soft warm-brown outlines, warm pastel palette, "
    "simple rounded shapes, adorable, toddler-friendly, storybook quality. "
)

MILO_DESC = (
    "the exact same character: an original cute small round peachy-orange "
    "animal mascot with tall rounded ears with pink inner ears, cream belly "
    "patch, large warm brown eyes with white catchlights, rosy blush "
    "cheeks, small arms and feet, tiny curled tail"
)

ITEMS = {
    "animal_rabbit": "a cute white-cream baby rabbit sitting, long ears, smiling",
    "animal_cow": "a cute baby cow standing, cream body with soft brown patches, pink muzzle, smiling",
    "animal_monkey": "a cute baby monkey sitting, brown fur, lighter face, smiling",
    "animal_duck": "a cute yellow duckling standing, orange beak, smiling",
    "animal_fish": "a cute smiling coral-pink fish with big friendly eye",
    "animal_cat": "a cute peach kitten sitting, striped tail, whiskers, smiling",
    "animal_dog": "a cute light-brown puppy sitting, floppy ears, smiling",
    "animal_bee": "a cute round smiling bee with soft yellow and brown stripes and small blue wings",
    "animal_butterfly": "a cute smiling butterfly with round pink and lavender wings",
    "animal_ladybug": "a cute smiling round red ladybug with dark dots",
    "food_apple": "a shiny red apple with a green leaf",
    "food_banana": "a cheerful yellow banana",
    "food_strawberry": "a bright red strawberry with green top and tiny seeds",
    "food_orange": "a round orange fruit with a green leaf",
    "food_pear": "a soft green pear",
    "food_grapes": "a small bunch of purple grapes with a leaf",
    "food_bread": "a warm golden loaf of bread",
    "food_milk": "a friendly white milk bottle with a blue cap",
    "food_cheese": "a yellow cheese wedge with holes",
    "food_egg": "a simple white egg",
    "food_carrot": "an orange carrot with green leafy top",
    "food_cookie": "a round cookie with chocolate chips",
    "vehicle_car": "a cute little red car with round windows, side view",
    "vehicle_bus": "a cute yellow school bus with round windows, side view",
    "vehicle_boat": "a cute little sailboat with red hull and white sail",
    "vehicle_rocket": "a cute little blue rocket with round window and orange flame",
}

MILO_POSES = {
    "idle": "standing calmly with little arms relaxed at the sides, gentle happy face",
    "talking": "standing with one arm slightly raised, mouth open mid-speech, friendly expression",
    "pointing": "pointing enthusiastically to the right side with one arm fully extended",
    "happy": "jumping for joy with both arms up, huge happy smile, eyes closed with joy",
    "laughing": "laughing heartily, eyes closed, big open smile, hands near belly",
    "surprised": "surprised with wide eyes and small round open mouth, hands raised",
    "dancing": "dancing playfully with arms out and one foot lifted, joyful",
    "sleepy": "very sleepy with eyes closed, gentle smile, slightly slumped, cozy",
}

SCENES = {
    "home_meadow": "a wide gentle meadow with soft green rolling hills, a few simple flowers, "
        "large calm sky with room at the top, no characters, no sun, no clouds in the upper half",
    "scene_farm": "a friendly little farm: soft green field, small red barn in the distance, "
        "wooden fence, big calm sky, no animals, no characters",
    "scene_underwater": "a calm underwater world: soft aqua-blue water, gentle light rays, "
        "rounded coral and seaweed at the bottom edges, small bubbles, no fish, no characters",
    "scene_bedroom": "a cozy child's bedroom: warm peach wall, a window with daylight, "
        "small dresser, soft rug on wooden floor, no characters",
    "scene_bath": "a sunny backyard bath corner: soft grass, a big wooden washtub, "
        "hanging towel, gentle sky, no animals, no characters",
    "scene_workshop": "a friendly space workshop at evening: soft lavender walls, a big round "
        "window showing stars, workbench, small shelf with tools, no characters",
    "scene_night": "a cozy child's bedroom at night: dim warm light, bed with pillow and "
        "blanket, window showing dusk sky with early stars, small nightstand lamp, no characters",
    "scene_activity": "a very soft abstract backdrop for a children's learning game: gentle "
        "sky-blue to cream vertical gradient, a few faint rounded cloud shapes, extremely "
        "minimal, lots of empty space, no characters, no objects in the center",
    "sticker_meadow": "a bright simple meadow scene for a sticker book: green hills, "
        "blue sky, one small sun, mostly empty space, no characters",
    "sticker_sky": "a bright simple sky scene for a sticker book: blue sky, a few fluffy "
        "white clouds, mostly empty space, no characters",
    "sticker_sea": "a bright simple ocean scene for a sticker book: aqua water, gentle "
        "waves, sandy bottom edge, mostly empty space, no fish, no characters",
}


def api(path, payload=None, files=None, key=None, retries=4):
    """JSON or multipart request with backoff."""
    url = f"https://api.openai.com/v1/{path}"
    for attempt in range(retries):
        try:
            if files is None:
                req = urllib.request.Request(
                    url, data=json.dumps(payload).encode(),
                    headers={"Authorization": f"Bearer {key}",
                             "Content-Type": "application/json"})
            else:
                boundary = uuid.uuid4().hex
                body = io.BytesIO()
                for k, v in payload.items():
                    body.write(f"--{boundary}\r\nContent-Disposition: "
                               f"form-data; name=\"{k}\"\r\n\r\n{v}\r\n"
                               .encode())
                for k, (name, data) in files.items():
                    ctype = mimetypes.guess_type(name)[0] or "image/png"
                    body.write(f"--{boundary}\r\nContent-Disposition: "
                               f"form-data; name=\"{k}\"; filename=\"{name}\""
                               f"\r\nContent-Type: {ctype}\r\n\r\n".encode())
                    body.write(data)
                    body.write(b"\r\n")
                body.write(f"--{boundary}--\r\n".encode())
                req = urllib.request.Request(
                    url, data=body.getvalue(),
                    headers={"Authorization": f"Bearer {key}",
                             "Content-Type":
                                 f"multipart/form-data; boundary={boundary}"})
            with urllib.request.urlopen(req, timeout=600) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            detail = e.read().decode()[:300]
            if e.code in (429, 500, 502, 503) and attempt < retries - 1:
                wait = 2 ** (attempt + 2)
                print(f"  retry in {wait}s ({e.code}): {detail[:120]}")
                time.sleep(wait)
                continue
            raise RuntimeError(f"{path} failed ({e.code}): {detail}") from e
    raise RuntimeError("unreachable")


def b64_image(result):
    return base64.b64decode(result["data"][0]["b64_json"])


def generate(key, prompt, size, transparent):
    payload = {"model": MODEL, "prompt": prompt, "size": size,
               "quality": "medium", "n": 1}
    if transparent:
        payload["background"] = "transparent"
    return b64_image(api("images/generations", payload, key=key))


def edit(key, anchor_bytes, prompt, size):
    return b64_image(api(
        "images/edits",
        {"model": MODEL, "prompt": prompt, "size": size,
         "quality": "medium", "background": "transparent"},
        files={"image": ("anchor.png", anchor_bytes)},
        key=key))


def process_transparent(raw, out_path, target):
    """Trim transparent margins, pad square, downscale, save PNG."""
    im = Image.open(io.BytesIO(raw)).convert("RGBA")
    bbox = im.getchannel("A").getbbox()
    if bbox:
        im = im.crop(bbox)
    side = max(im.size)
    pad = Image.new("RGBA", (int(side * 1.06), int(side * 1.06)),
                    (0, 0, 0, 0))
    pad.paste(im, ((pad.width - im.width) // 2,
                   (pad.height - im.height) // 2))
    pad.thumbnail((target, target), Image.LANCZOS)
    pad.save(out_path, optimize=True)


def process_scene(raw, out_path):
    im = Image.open(io.BytesIO(raw)).convert("RGB")
    im.save(out_path, "JPEG", quality=86, optimize=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--anchor", required=True,
                        help="style-anchor PNG of Milo (transparent)")
    parser.add_argument("--workdir", default=os.path.join(ROOT, ".art_raw"),
                        help="cache for raw generations (gitignored)")
    parser.add_argument("--only", choices=["items", "milo", "scenes"])
    args = parser.parse_args()

    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        sys.exit("Set OPENAI_API_KEY")

    os.makedirs(args.workdir, exist_ok=True)
    items_dir = os.path.join(ROOT, "assets", "images", "items")
    milo_dir = os.path.join(ROOT, "assets", "images", "milo")
    scenes_dir = os.path.join(ROOT, "assets", "images", "scenes")
    for d in (items_dir, milo_dir, scenes_dir):
        os.makedirs(d, exist_ok=True)

    with open(args.anchor, "rb") as f:
        anchor = f.read()

    jobs = []
    if args.only in (None, "items"):
        for item_id, desc in ITEMS.items():
            jobs.append(("item", item_id, desc))
    if args.only in (None, "milo"):
        for pose, desc in MILO_POSES.items():
            jobs.append(("milo", pose, desc))
    if args.only in (None, "scenes"):
        for scene_id, desc in SCENES.items():
            jobs.append(("scene", scene_id, desc))

    def run(job):
        kind, name, desc = job
        raw_path = os.path.join(args.workdir, f"{kind}_{name}.png")
        if kind == "item":
            out = os.path.join(items_dir, f"{name}.png")
        elif kind == "milo":
            out = os.path.join(milo_dir, f"{name}.png")
        else:
            out = os.path.join(scenes_dir, f"{name}.jpg")
        if os.path.exists(out):
            return f"skip {kind}/{name}"
        try:
            if os.path.exists(raw_path):
                with open(raw_path, "rb") as f:
                    raw = f.read()
            elif kind == "item":
                prompt = (f"{STYLE}A single {desc}. Centered, full object "
                          "visible, one connected shape, big and simple, "
                          "isolated on a fully transparent background.")
                raw = generate(key, prompt, "1024x1024", True)
            elif kind == "milo":
                prompt = (f"{STYLE}Redraw {MILO_DESC}, {desc}. Keep the "
                          "identical art style, colors and proportions. "
                          "Full body, centered, transparent background.")
                raw = edit(key, anchor, prompt, "1024x1024")
            else:
                prompt = (f"{STYLE}Background scene for a children's game: "
                          f"{desc}. Landscape composition with a calm, "
                          "uncluttered center area where game objects will "
                          "be placed. Soft colors, gentle light.")
                raw = generate(key, prompt, "1536x1024", False)
            with open(raw_path, "wb") as f:
                f.write(raw)
            if kind == "scene":
                process_scene(raw, out)
            else:
                process_transparent(raw, out,
                                    512 if kind == "milo" else 384)
            return f"done {kind}/{name}"
        except Exception as e:  # noqa: BLE001 — report and continue
            return f"FAIL {kind}/{name}: {str(e)[:200]}"

    with ThreadPoolExecutor(max_workers=3) as pool:
        for message in pool.map(run, jobs):
            print(message)


if __name__ == "__main__":
    main()
