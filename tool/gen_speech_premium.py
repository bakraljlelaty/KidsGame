#!/usr/bin/env python3
"""OPTIONAL: near-human voices via the ElevenLabs API (paid, ~$5 tier).

This is the middle path between the bundled offline neural voices (free,
already good) and hiring voice actors (best). ElevenLabs' multilingual
model produces very natural Arabic and English child-friendly narration,
and paid plans include a commercial license for generated audio — verify
the current terms for your plan before shipping.

Usage:
    export ELEVEN_API_KEY=...            # from elevenlabs.io
    python3 tool/gen_speech_premium.py                 # both languages
    python3 tool/gen_speech_premium.py --language ar   # one language
    # optional voice overrides:
    export ELEVEN_VOICE_EN=<voice_id>    # default: Rachel-style narrator
    export ELEVEN_VOICE_AR=<voice_id>    # pick an Arabic-capable voice

The same catalogs drive all backends, so clip ids/text stay identical.
Generated files land in assets/audio/voices/<lang>/<id>.ogg (via ffmpeg).
"""

import json
import os
import subprocess
import sys
import tempfile
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_speech  # noqa: E402

API = "https://api.elevenlabs.io/v1/text-to-speech"
MODEL = "eleven_multilingual_v2"

DEFAULT_VOICES = {
    # Replace with the voice ids you audition on elevenlabs.io/voice-library
    "en": os.environ.get("ELEVEN_VOICE_EN", "21m00Tcm4TlvDq8ikWAM"),
    "ar": os.environ.get("ELEVEN_VOICE_AR", "21m00Tcm4TlvDq8ikWAM"),
}


def synthesize(api_key, voice_id, text, mp3_path):
    payload = json.dumps({
        "text": text,
        "model_id": MODEL,
        "voice_settings": {"stability": 0.6, "similarity_boost": 0.8,
                           "style": 0.25},
    }).encode()
    request = urllib.request.Request(
        f"{API}/{voice_id}",
        data=payload,
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        with open(mp3_path, "wb") as f:
            f.write(response.read())


def to_ogg(src, dst):
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", src,
         "-af", "loudnorm=I=-18:TP=-2:LRA=9",
         "-ac", "1", "-ar", "22050", "-c:a", "libvorbis", "-q:a", "3", dst],
        check=True, capture_output=True,
    )


def main():
    api_key = os.environ.get("ELEVEN_API_KEY")
    if not api_key:
        sys.exit("Set ELEVEN_API_KEY first (see file docstring).")

    only = None
    if "--language" in sys.argv:
        only = sys.argv[sys.argv.index("--language") + 1]

    ids = gen_speech.enum_ids()
    for lang, catalog in (("en", gen_speech.EN), ("ar", gen_speech.AR)):
        if only and lang != only:
            continue
        out_dir = os.path.join(gen_speech.VOICES_DIR, lang)
        os.makedirs(out_dir, exist_ok=True)
        for i, clip_id in enumerate(ids, 1):
            text = catalog[clip_id]
            voice_lang = lang
            if text is None:  # cross-language letter clips keep their voice
                voice_lang = "ar" if clip_id.startswith("ar_") else "en"
                text = (gen_speech.AR if voice_lang == "ar"
                        else gen_speech.EN)[clip_id]
            with tempfile.NamedTemporaryFile(suffix=".mp3") as tmp:
                synthesize(api_key, DEFAULT_VOICES[voice_lang], text,
                           tmp.name)
                to_ogg(tmp.name, os.path.join(out_dir, f"{clip_id}.ogg"))
            print(f"[{lang}] {i}/{len(ids)} {clip_id}")

    print("Done. Rebuild the app to hear the new voice.")


if __name__ == "__main__":
    main()
