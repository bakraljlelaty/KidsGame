#!/usr/bin/env python3
"""Imports human voice recordings into the app.

Point it at a folder containing `en/` and/or `ar/` subfolders where each
recording is named by its clip id (see docs/VOICE_RECORDING_SCRIPT.md):

    recordings/
      en/ welcome.wav  find_it.m4a  ...
      ar/ welcome.wav  ...

Any common format works (wav, mp3, m4a, aac, ogg, flac). Each file is:
  1. loudness-normalized (EBU R128, -18 LUFS — gentle for children),
  2. silence-trimmed at both ends,
  3. converted to 22050 Hz mono OGG Vorbis,
  4. written to assets/audio/voices/<lang>/<clip_id>.ogg.

Then a coverage report lists any clips still missing (those keep their
current synthetic audio, so a partial recording session is always safe).

Run from the repo root:
    python3 tool/import_recordings.py /path/to/recordings
    python3 tool/import_recordings.py /path/to/recordings --language ar
"""

import argparse
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_speech  # noqa: E402

AUDIO_EXTS = {".wav", ".mp3", ".m4a", ".aac", ".ogg", ".flac"}


def convert(src, dst):
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error", "-i", src,
            "-af",
            "loudnorm=I=-18:TP=-2:LRA=9,"
            "silenceremove=start_periods=1:start_threshold=-45dB:"
            "start_silence=0.15,areverse,"
            "silenceremove=start_periods=1:start_threshold=-45dB:"
            "start_silence=0.15,areverse",
            "-ac", "1", "-ar", "22050", "-c:a", "libvorbis", "-q:a", "3",
            dst,
        ],
        check=True, capture_output=True,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", help="folder with en/ and/or ar/ subdirs")
    parser.add_argument("--language", choices=["en", "ar"],
                        help="import only one language")
    args = parser.parse_args()

    ids = set(gen_speech.enum_ids())
    languages = [args.language] if args.language else ["en", "ar"]
    any_imported = False

    for lang in languages:
        src_dir = os.path.join(args.source, lang)
        if not os.path.isdir(src_dir):
            print(f"[{lang}] no {src_dir} — skipped")
            continue

        out_dir = os.path.join(gen_speech.VOICES_DIR, lang)
        os.makedirs(out_dir, exist_ok=True)
        imported, unknown, failed = [], [], []

        for name in sorted(os.listdir(src_dir)):
            stem, ext = os.path.splitext(name)
            if ext.lower() not in AUDIO_EXTS:
                continue
            if stem not in ids:
                unknown.append(name)
                continue
            try:
                convert(os.path.join(src_dir, name),
                        os.path.join(out_dir, f"{stem}.ogg"))
                imported.append(stem)
            except subprocess.CalledProcessError as e:
                failed.append((name, e.stderr.decode()[:200]))

        missing = sorted(ids - set(imported))
        print(f"[{lang}] imported {len(imported)} clips")
        if unknown:
            print(f"[{lang}] ignored (unknown clip ids): {unknown}")
        for name, err in failed:
            print(f"[{lang}] FAILED {name}: {err}")
        if imported and missing:
            print(f"[{lang}] still synthetic ({len(missing)}): "
                  f"{', '.join(missing[:12])}"
                  f"{' …' if len(missing) > 12 else ''}")
        any_imported = any_imported or bool(imported)

    if any_imported:
        print("\nDone. Rebuild the app to hear the new voice "
              "(flutter build apk --release).")


if __name__ == "__main__":
    main()
