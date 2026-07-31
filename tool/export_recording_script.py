#!/usr/bin/env python3
"""Exports the voice-actor recording script from the speech catalogs.

Outputs:
  docs/VOICE_RECORDING_SCRIPT.md  — printable script with tone directions
  tool/recording_script.csv       — spreadsheet form for studios

Run from the repo root:  python3 tool/export_recording_script.py
"""

import csv
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_speech  # noqa: E402  (reuses EN/AR catalogs + enum parsing)

ROOT = gen_speech.ROOT

SECTIONS = [
    ("Milo — greetings & celebration", "warm, smiling, unhurried; celebrate "
     "gently (never shout)", [
         "welcome", "choose_game", "great_job", "well_done", "try_again",
         "sticker_earned", "level_up", "unit_done", "path_intro",
         "rooms_intro"]),
    ("Session & bedtime — calm and slow", "soft, slow, sleepy warmth", [
        "session_over", "good_night", "bedtime_intro", "bedtime_toys",
        "bedtime_teeth", "bedtime_pajamas", "bedtime_teddy",
        "bedtime_light", "bedtime_done"]),
    ("Game instructions", "clear, warm, a touch of playful invitation; "
     "pause slightly between clauses", [
         "feed_intro", "feed_rabbit", "feed_cow", "feed_monkey",
         "bubble_intro", "pop_blue", "pop_yellow", "pop_red", "pop_green",
         "pop_fish", "pop_star", "pop_heart", "pop_then_next",
         "socks_intro", "socks_find", "pig_intro", "pig_scrub",
         "pig_rinse", "pig_dry", "pig_clean", "rocket_intro",
         "rocket_piece", "rocket_launch", "find_it", "sort_intro",
         "sort_next", "shadow_intro", "shadow_next", "memory_intro",
         "memory_pair_found", "pattern_intro", "pattern_next",
         "count_intro", "give_me", "trace_intro", "trace_follow",
         "paint_intro", "paint_done"]),
    ("Numbers (counting voice — bright, rhythmic)", "bright and rhythmic, "
     "as if counting on fingers", [
         f"count_{w}" for w in gen_speech.EN_NUMBERS]),
    ("Colors", "single joyful word, consistent energy across all", [
        "color_red", "color_blue", "color_yellow", "color_green",
        "color_orange", "color_purple", "color_pink"]),
    ("Shapes", "single clear word", [
        "shape_circle", "shape_square", "shape_triangle", "shape_star",
        "shape_heart", "shape_rectangle", "shape_oval", "shape_diamond"]),
    ("Animal & food names", "bright, affectionate", [
        "name_rabbit", "name_cow", "name_monkey", "name_duck", "name_fish",
        "name_cat", "name_dog", "name_bee", "name_butterfly",
        "name_ladybug", "name_apple", "name_banana", "name_strawberry",
        "name_orange", "name_pear", "name_grapes", "name_bread",
        "name_milk", "name_cheese", "name_egg", "name_carrot",
        "name_cookie"]),
    ("English letters (English narrator only)", "letter name, clear and "
     "friendly", [f"letter_{chr(c)}" for c in range(ord('a'), ord('z') + 1)]),
    ("Arabic letters (Arabic narrator only)", "letter name, clear and "
     "friendly / اسم الحرف بوضوح ولطف", list(gen_speech.AR_LETTER_NAMES)),
]


def main():
    ids = gen_speech.enum_ids()
    covered = {i for _, _, id_list in SECTIONS for i in id_list}
    missing = [i for i in ids if i not in covered]
    if missing:
        sys.exit(f"Recording script is missing ids: {missing}")

    md_path = os.path.join(ROOT, "docs", "VOICE_RECORDING_SCRIPT.md")
    csv_path = os.path.join(ROOT, "tool", "recording_script.csv")

    with open(md_path, "w") as md:
        md.write(
            "# Voice Recording Script — Little Wonder Academy\n\n"
            "One row per clip. Record **each clip as its own file**, named\n"
            "exactly `<clip id>.wav` (English takes en/, Arabic takes ar/),\n"
            "then run `python3 tool/import_recordings.py <folder>`.\n\n"
            "**Studio notes**\n\n"
            "- Narrator: warm, unhurried, smiling — speaking to a 2–6 year\n"
            "  old. Never sharp, never loud; celebrations are gentle joy,\n"
            "  not shouting.\n"
            "- Format: WAV, 44.1 kHz or higher, mono, quiet room. Leave\n"
            "  ~0.2 s of silence at both ends (the importer trims).\n"
            "- Keep energy and microphone distance consistent across the\n"
            "  whole session; the counting words and color/shape/name words\n"
            "  should feel like one matched family.\n"
            "- Arabic is written fully vocalized (مُشَكَّل) — please follow\n"
            "  the diacritics; Modern Standard Arabic with a soft, friendly\n"
            "  delivery.\n\n")
        for title, direction, id_list in SECTIONS:
            md.write(f"## {title}\n\n*Direction: {direction}*\n\n")
            md.write("| Clip id | English | العربية |\n|---|---|---|\n")
            for clip_id in id_list:
                en = gen_speech.EN.get(clip_id) or "—"
                ar = gen_speech.AR.get(clip_id) or "—"
                md.write(f"| `{clip_id}` | {en} | {ar} |\n")
            md.write("\n")

    with open(csv_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["clip_id", "section", "direction", "english",
                         "arabic"])
        for title, direction, id_list in SECTIONS:
            for clip_id in id_list:
                writer.writerow([
                    clip_id, title, direction,
                    gen_speech.EN.get(clip_id) or "",
                    gen_speech.AR.get(clip_id) or "",
                ])

    print(f"wrote {md_path}")
    print(f"wrote {csv_path}")


if __name__ == "__main__":
    main()
