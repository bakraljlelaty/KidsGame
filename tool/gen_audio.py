#!/usr/bin/env python3
"""Generates all placeholder audio for Little Wonder World.

Every file is an original, programmatically synthesized WAV (soft sine-based
chimes) — no copyrighted or licensed material. Real recordings can replace
these files 1:1 (same names, see AUDIO_GUIDE.md).

Run from the repo root:  python3 tool/gen_audio.py
"""

import math
import os
import re
import struct
import wave

RATE = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "assets", "audio")


def write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)


def silence(duration):
    return [0.0] * int(RATE * duration)


def tone(freq, duration, volume=0.5, attack=0.02, release=None, harmonics=True):
    """A soft sine tone with gentle attack/release and a hint of overtone."""
    n = int(RATE * duration)
    release = release if release is not None else duration * 0.6
    out = []
    for i in range(n):
        t = i / RATE
        env = 1.0
        if t < attack:
            env = t / attack
        remaining = duration - t
        if remaining < release:
            env *= max(0.0, remaining / release)
        s = math.sin(2 * math.pi * freq * t)
        if harmonics:
            s += 0.25 * math.sin(2 * math.pi * freq * 2 * t)
            s += 0.08 * math.sin(2 * math.pi * freq * 3 * t)
        out.append(s * env * volume / 1.33)
    return out


def sweep(f0, f1, duration, volume=0.5):
    n = int(RATE * duration)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = f0 + (f1 - f0) * (t / duration)
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / 0.01) * max(0.0, 1 - t / duration)
        out.append(math.sin(phase) * env * volume)
    return out


def soft_noise(duration, volume=0.25, lp=0.15):
    """Low-passed pseudo-noise for water-ish sounds (deterministic)."""
    n = int(RATE * duration)
    out = []
    value = 0.0
    seed = 12345
    for i in range(n):
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        rnd = (seed / 0x7FFFFFFF) * 2 - 1
        value += lp * (rnd - value)
        t = i / RATE
        env = min(1.0, t / 0.03) * max(0.0, 1 - t / duration)
        out.append(value * env * volume * 3)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for p in parts:
        for i, s in enumerate(p):
            out[i] += s
    peak = max(1.0, max(abs(s) for s in out))
    return [s / peak * 0.9 for s in out]


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


# Pentatonic-ish gentle notes.
C4, D4, E4, G4, A4 = 261.63, 293.66, 329.63, 392.0, 440.0
C5, D5, E5, G5, A5 = 523.25, 587.33, 659.25, 783.99, 880.0
C6, E6 = 1046.5, 1318.5


def effects():
    return {
        "pop": sweep(420, 880, 0.12, 0.5),
        "chime_success": seq(tone(C5, 0.16, 0.5), tone(E5, 0.3, 0.5)),
        "chime_soft": tone(A4, 0.3, 0.4),
        "boing_soft": sweep(320, 150, 0.28, 0.4),
        "water_splash": mix(soft_noise(0.35, 0.3), sweep(900, 500, 0.2, 0.12)),
        "chew": seq(tone(180, 0.09, 0.4, harmonics=False), silence(0.06),
                    tone(150, 0.1, 0.4, harmonics=False)),
        "sparkle": seq(tone(C6, 0.09, 0.32), tone(E6, 0.09, 0.32),
                       tone(C6 * 1.5, 0.2, 0.3)),
        "yawn": sweep(420, 190, 0.8, 0.3),
        "slide": sweep(520, 330, 0.2, 0.28),
        "ding": tone(E6, 0.28, 0.4),
        "celebrate": seq(tone(C5, 0.14, 0.5), tone(E5, 0.14, 0.5),
                         tone(G5, 0.14, 0.5), tone(C6, 0.4, 0.5)),
        "session_reminder": seq(tone(G4, 0.25, 0.35), tone(E4, 0.4, 0.35)),
        "night_calm": mix(tone(C4, 1.6, 0.25, attack=0.4),
                          tone(E4, 1.6, 0.2, attack=0.5),
                          tone(G4, 1.6, 0.16, attack=0.6)),
    }


def music_calm():
    """~12 s gentle arpeggio loop."""
    pattern = [C4, E4, G4, C5, G4, E4]
    chords = [0, 1.0, 1.25, 1.0]  # I, IV-ish, V-ish shifts by ratio
    out = []
    for ratio in [1.0, 4 / 3, 3 / 2, 1.0]:
        for note in pattern:
            out.extend(tone(note * ratio, 0.5, 0.22, attack=0.08,
                            release=0.35))
    return out


def music_lullaby():
    out = []
    melody = [E4, D4, C4, D4, E4, E4, E4]
    for note in melody:
        out.extend(tone(note, 0.8, 0.2, attack=0.15, release=0.5))
    out.extend(tone(C4, 1.6, 0.18, attack=0.2, release=1.0))
    return out


def voice_instruction_ids():
    """Reads the VoiceInstruction enum so audio stays in sync with code."""
    path = os.path.join(ROOT, "lib", "core", "audio", "voice_catalog.dart")
    with open(path) as f:
        src = f.read()
    body = re.search(r"enum VoiceInstruction \{(.*?)\}", src, re.S).group(1)
    body = re.sub(r"//[^\n]*", "", body)  # strip comments
    names = re.findall(r"\b([a-zA-Z][a-zA-Z0-9]*)\s*,", body)
    snake = [re.sub(r"([A-Z])", lambda m: "_" + m.group(1).lower(), n)
             for n in names]
    return snake


def voice_placeholder(file_id, lang):
    """A distinct, gentle two-tone pattern per instruction (so testers can
    tell prompts apart) — clearly a placeholder, replaced by recordings."""
    h = sum((i + 1) * ord(c) for i, c in enumerate(file_id + lang))
    notes = [C5, D5, E5, G5, A5]
    first = notes[h % len(notes)]
    second = notes[(h // 7) % len(notes)]
    third = notes[(h // 31) % len(notes)]
    return seq(tone(first, 0.18, 0.4), silence(0.05),
               tone(second, 0.18, 0.4), silence(0.05),
               tone(third, 0.28, 0.4))


def main():
    for name, samples in effects().items():
        write_wav(os.path.join(AUDIO, "effects", f"{name}.wav"), samples)
        print("effect ", name)

    write_wav(os.path.join(AUDIO, "music", "calm_loop.wav"), music_calm())
    write_wav(os.path.join(AUDIO, "music", "lullaby_loop.wav"),
              music_lullaby())
    print("music   calm_loop, lullaby_loop")

    for lang in ("en", "ar"):
        for file_id in voice_instruction_ids():
            write_wav(os.path.join(AUDIO, "voices", lang,
                                   f"{file_id}.wav"),
                      voice_placeholder(file_id, lang))
        print(f"voices  {lang}: done")


if __name__ == "__main__":
    main()
