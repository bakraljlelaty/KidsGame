#!/usr/bin/env python3
"""Generates spoken voice instructions for both app languages.

Primary backend: Piper neural TTS (natural offline voices, generated once at
build time — the app itself stays fully offline). Fallback backend:
espeak-ng, used automatically when the Piper models are not present.

Output: assets/audio/voices/<en|ar>/<id>.ogg (22050 Hz OGG Vorbis). Replace
any clip with a human recording of the same name for release.

Setup (once):
    pip install piper-tts
    mkdir -p tool/piper_models && cd tool/piper_models
    # from https://huggingface.co/rhasspy/piper-voices :
    #   ar/ar_JO/kareem/medium/ar_JO-kareem-medium.onnx (+ .onnx.json)
    #   en/en_US/hfc_female/medium/en_US-hfc_female-medium.onnx (+ .onnx.json)
    # (model dir override: PIPER_MODEL_DIR=/path python3 tool/gen_speech.py)

Arabic strings are fully diacritized (مُشَكَّلة) — both Piper's Arabic model
and espeak-ng pronounce vocalized text far more accurately.

Run from the repo root:  python3 tool/gen_speech.py
"""

import os
import re
import subprocess
import sys
import tempfile
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VOICES_DIR = os.path.join(ROOT, "assets", "audio", "voices")
MODEL_DIR = os.environ.get(
    "PIPER_MODEL_DIR", os.path.join(ROOT, "tool", "piper_models"))

PIPER_MODELS = {
    "en": "en_US-hfc_female-medium.onnx",
    "ar": "ar_JO-kareem-medium.onnx",
}
# Slightly slower than default so small children can follow.
PIPER_LENGTH_SCALE = {"en": 1.08, "ar": 1.12}

ESPEAK_VOICE = {
    "en": ["-v", "en-us+f3", "-s", "128", "-p", "66", "-a", "180"],
    "ar": ["-v", "ar+f3", "-s", "118", "-p", "62", "-a", "180"],
}

# ---------------------------------------------------------------- catalogs

EN = {
    "welcome": "Hi! I'm Milo! Let's play together!",
    "choose_game": "Pick a game! Which one do you like?",
    "great_job": "Great job! You did it!",
    "well_done": "Well done! That was wonderful!",
    "try_again": "Hmm, let's try again!",
    "sticker_earned": "You got a new sticker! Yay!",
    "session_over": "Play time is over for now. See you soon!",
    "good_night": "Good night! Sleep tight!",
    "feed_intro": "The animals are hungry! Let's feed them!",
    "feed_rabbit": "Give the carrot to the bunny!",
    "feed_cow": "Give the grass to the cow!",
    "feed_monkey": "Give the banana to the monkey!",
    "bubble_intro": "Look at all the bubbles!",
    "pop_blue": "Pop the blue bubble!",
    "pop_yellow": "Pop the yellow bubble!",
    "pop_red": "Pop the red bubble!",
    "pop_green": "Pop the green bubble!",
    "pop_fish": "Pop the bubble with the fish!",
    "pop_star": "Pop the bubble with the star!",
    "pop_heart": "Pop the bubble with the heart!",
    "pop_then_next": "Now the next one!",
    "socks_intro": "The socks lost their friends!",
    "socks_find": "Find the matching sock!",
    "pig_intro": "Oh no, the pig is all muddy! Let's wash it!",
    "pig_scrub": "Rub the sponge on the mud!",
    "pig_rinse": "Tap the water to rinse!",
    "pig_dry": "Dry the pig with the towel!",
    "pig_clean": "So clean! What a happy pig!",
    "rocket_intro": "Let's build a rocket!",
    "rocket_piece": "Put the piece on its shadow!",
    "rocket_launch": "Three, two, one, up we go!",
    "bedtime_intro": "It's almost bedtime. Let's get ready!",
    "bedtime_toys": "Put the toy in the basket!",
    "bedtime_teeth": "Let's brush my teeth!",
    "bedtime_pajamas": "Help me put on my pajamas!",
    "bedtime_teddy": "Put the teddy bear in the bed!",
    "bedtime_light": "Turn off the light!",
    "bedtime_done": "Good night! Sweet dreams!",
    "find_it": "Can you find it? Tap it!",
    "sort_intro": "Let's tidy up! Put each one in its basket!",
    "sort_next": "Wonderful! What about this one?",
    "shadow_intro": "Every friend has a shadow! Match them!",
    "shadow_next": "Yes! Find the next shadow!",
    "memory_intro": "Flip the cards and find the pairs!",
    "memory_pair_found": "A pair! You found it!",
    "pattern_intro": "Look at the pattern!",
    "pattern_next": "What comes next?",
    "count_intro": "Let's count together!",
    "give_me": "Can you give me...",
    "trace_intro": "Let's draw with your finger!",
    "trace_follow": "Follow the line from the dot!",
    "unit_done": "You finished the whole unit! Amazing!",
    "path_intro": "This is our learning path! Tap the glowing circle!",
    "rooms_intro": "Choose a room to play in!",
    "level_up": "You're getting so good at this!",
    "paint_intro": "Let's paint! Use your finger!",
    "paint_done": "What a beautiful picture!",
    "color_red": "Red!",
    "color_blue": "Blue!",
    "color_yellow": "Yellow!",
    "color_green": "Green!",
    "color_orange": "Orange!",
    "color_purple": "Purple!",
    "color_pink": "Pink!",
    "shape_circle": "A circle!",
    "shape_square": "A square!",
    "shape_triangle": "A triangle!",
    "shape_star": "A star!",
    "shape_heart": "A heart!",
    "shape_rectangle": "A rectangle!",
    "shape_oval": "An oval!",
    "shape_diamond": "A diamond!",
    "name_rabbit": "The bunny!",
    "name_cow": "The cow!",
    "name_monkey": "The monkey!",
    "name_duck": "The duck!",
    "name_fish": "The fish!",
    "name_cat": "The cat!",
    "name_dog": "The dog!",
    "name_bee": "The bee!",
    "name_butterfly": "The butterfly!",
    "name_ladybug": "The ladybug!",
    "name_apple": "The apple!",
    "name_banana": "The banana!",
    "name_strawberry": "The strawberry!",
    "name_orange": "The orange!",
    "name_pear": "The pear!",
    "name_grapes": "The grapes!",
    "name_bread": "The bread!",
    "name_milk": "The milk!",
    "name_cheese": "The cheese!",
    "name_egg": "The egg!",
    "name_carrot": "The carrot!",
    "name_cookie": "The cookie!",
}

# Fully vocalized Modern Standard Arabic, warm and child-directed.
AR = {
    "welcome": "أَهْلاً! أَنا مِيلُو! هَيَّا نَلْعَبُ مَعاً!",
    "choose_game": "اِخْتَرْ لُعْبَةً! أَيُّها تُحِبُّ؟",
    "great_job": "أَحْسَنْتَ! لَقَدْ نَجَحْتَ!",
    "well_done": "رائِعٌ! كانَ هٰذا جَميلاً جِدّاً!",
    "try_again": "هَيَّا نُحاوِلُ مَرَّةً أُخْرَى!",
    "sticker_earned": "حَصَلْتَ عَلَى مُلْصَقٍ جَديدٍ! يا سَلامْ!",
    "session_over": "اِنْتَهَى وَقْتُ اللَّعِبِ الآنَ. إِلَى اللِّقاءِ قَريباً!",
    "good_night": "تُصْبِحُ عَلَى خَيْرٍ! نَوْماً هَنيئاً!",
    "feed_intro": "الحَيَواناتُ جائِعَةٌ! هَيَّا نُطْعِمُها!",
    "feed_rabbit": "أَعْطِ الجَزَرَةَ لِلأَرْنَبِ!",
    "feed_cow": "أَعْطِ العُشْبَ لِلْبَقَرَةِ!",
    "feed_monkey": "أَعْطِ المَوْزَةَ لِلْقِرْدِ!",
    "bubble_intro": "اُنْظُرْ إِلَى كُلِّ هٰذِهِ الفُقَّاعاتِ!",
    "pop_blue": "اِضْغَطْ عَلَى الفُقَّاعَةِ الزَّرْقاءِ!",
    "pop_yellow": "اِضْغَطْ عَلَى الفُقَّاعَةِ الصَّفْراءِ!",
    "pop_red": "اِضْغَطْ عَلَى الفُقَّاعَةِ الحَمْراءِ!",
    "pop_green": "اِضْغَطْ عَلَى الفُقَّاعَةِ الخَضْراءِ!",
    "pop_fish": "اِضْغَطْ عَلَى فُقَّاعَةِ السَّمَكَةِ!",
    "pop_star": "اِضْغَطْ عَلَى فُقَّاعَةِ النَّجْمَةِ!",
    "pop_heart": "اِضْغَطْ عَلَى فُقَّاعَةِ القَلْبِ!",
    "pop_then_next": "وَالآنَ التّالِيَةُ!",
    "socks_intro": "الجَوارِبُ أَضاعَتْ أَصْدِقاءَها!",
    "socks_find": "جِدِ الجَوْرَبَ المُطابِقَ!",
    "pig_intro": "يا إِلٰهي، الخِنْزيرُ مَلِيءٌ بِالطِّينِ! هَيَّا نَغْسِلُهُ!",
    "pig_scrub": "اُفْرُكِ الإِسْفَنْجَةَ عَلَى الطِّينِ!",
    "pig_rinse": "اِضْغَطْ عَلَى الماءِ لِلشَّطْفِ!",
    "pig_dry": "جَفِّفِ الخِنْزيرَ بِالمِنْشَفَةِ!",
    "pig_clean": "نَظيفٌ تَماماً! يا لَهُ مِنْ خِنْزيرٍ سَعيدٍ!",
    "rocket_intro": "هَيَّا نَبْني صارُوخاً!",
    "rocket_piece": "ضَعِ القِطْعَةَ عَلَى ظِلِّها!",
    "rocket_launch": "ثَلاثَةٌ، اِثْنانِ، واحِدٌ، اِنْطَلِقْ!",
    "bedtime_intro": "اِقْتَرَبَ وَقْتُ النَّوْمِ. هَيَّا نَسْتَعِدُّ!",
    "bedtime_toys": "ضَعِ اللُّعْبَةَ في السَّلَّةِ!",
    "bedtime_teeth": "هَيَّا نُنَظِّفُ أَسْناني!",
    "bedtime_pajamas": "ساعِدْني في اِرْتِداءِ البيجاما!",
    "bedtime_teddy": "ضَعِ الدُّبْدُوبَ في السَّريرِ!",
    "bedtime_light": "أَطْفِئِ النُّورَ!",
    "bedtime_done": "تُصْبِحُ عَلَى خَيْرٍ! أَحْلاماً سَعيدَةً!",
    "find_it": "هَلْ تَجِدُهُ؟ اِضْغَطْ عَلَيْهِ!",
    "sort_intro": "هَيَّا نُرَتِّبُ! ضَعْ كُلَّ واحِدَةٍ في سَلَّتِها!",
    "sort_next": "رائِعٌ! وَماذا عَنْ هٰذِهِ؟",
    "shadow_intro": "لِكُلِّ صَديقٍ ظِلٌّ! طابِقْ بَيْنَهُما!",
    "shadow_next": "نَعَمْ! جِدِ الظِّلَّ التّالي!",
    "memory_intro": "اِقْلِبِ البِطاقاتِ وَجِدِ الأَزْواجَ!",
    "memory_pair_found": "زَوْجٌ مُتَطابِقٌ! لَقَدْ وَجَدْتَهُ!",
    "pattern_intro": "اُنْظُرْ إِلَى النَّمَطِ!",
    "pattern_next": "ماذا يَأْتي بَعْدَ ذٰلِكَ؟",
    "count_intro": "هَيَّا نَعُدُّ مَعاً!",
    "give_me": "هَلْ تُعْطيني...",
    "trace_intro": "هَيَّا نَرْسُمُ بِإِصْبَعِكَ!",
    "trace_follow": "اِتْبَعِ الخَطَّ مِنَ النُّقْطَةِ!",
    "unit_done": "أَنْهَيْتَ الوَحْدَةَ كامِلَةً! مُذْهِلٌ!",
    "path_intro": "هٰذا مَسارُ التَّعَلُّمِ! اِضْغَطْ عَلَى الدّائِرَةِ المُضيئَةِ!",
    "rooms_intro": "اِخْتَرْ غُرْفَةً لِتَلْعَبَ فيها!",
    "level_up": "أَنْتَ تَتَحَسَّنُ كَثيراً!",
    "paint_intro": "هَيَّا نَرْسُمُ! اِسْتَخْدِمْ إِصْبَعَكَ!",
    "paint_done": "يا لَها مِنْ لَوْحَةٍ جَميلَةٍ!",
    "color_red": "أَحْمَرُ!",
    "color_blue": "أَزْرَقُ!",
    "color_yellow": "أَصْفَرُ!",
    "color_green": "أَخْضَرُ!",
    "color_orange": "بُرْتُقالِيٌّ!",
    "color_purple": "بَنَفْسَجِيٌّ!",
    "color_pink": "وَرْدِيٌّ!",
    "shape_circle": "دائِرَةٌ!",
    "shape_square": "مُرَبَّعٌ!",
    "shape_triangle": "مُثَلَّثٌ!",
    "shape_star": "نَجْمَةٌ!",
    "shape_heart": "قَلْبٌ!",
    "shape_rectangle": "مُسْتَطيلٌ!",
    "shape_oval": "شَكْلٌ بَيْضاوِيٌّ!",
    "shape_diamond": "مُعَيَّنٌ!",
    "name_rabbit": "الأَرْنَبُ!",
    "name_cow": "البَقَرَةُ!",
    "name_monkey": "القِرْدُ!",
    "name_duck": "البَطَّةُ!",
    "name_fish": "السَّمَكَةُ!",
    "name_cat": "القِطَّةُ!",
    "name_dog": "الكَلْبُ!",
    "name_bee": "النَّحْلَةُ!",
    "name_butterfly": "الفَراشَةُ!",
    "name_ladybug": "الدُّعْسُوقَةُ!",
    "name_apple": "التُّفّاحَةُ!",
    "name_banana": "المَوْزَةُ!",
    "name_strawberry": "الفَراوِلَةُ!",
    "name_orange": "البُرْتُقالَةُ!",
    "name_pear": "الكُمَّثْرَى!",
    "name_grapes": "العِنَبُ!",
    "name_bread": "الخُبْزُ!",
    "name_milk": "الحَليبُ!",
    "name_cheese": "الجُبْنُ!",
    "name_egg": "البَيْضَةُ!",
    "name_carrot": "الجَزَرَةُ!",
    "name_cookie": "البَسْكَويتَةُ!",
}

EN_NUMBERS = ["one", "two", "three", "four", "five",
              "six", "seven", "eight", "nine", "ten"]
AR_NUMBERS = ["واحِدٌ", "اِثْنانِ", "ثَلاثَةٌ", "أَرْبَعَةٌ", "خَمْسَةٌ",
              "سِتَّةٌ", "سَبْعَةٌ", "ثَمانِيَةٌ", "تِسْعَةٌ", "عَشَرَةٌ"]

AR_LETTER_NAMES = {
    "ar_alif": "أَلِفْ", "ar_ba": "باءْ", "ar_ta": "تاءْ", "ar_tha": "ثاءْ",
    "ar_jim": "جيمْ", "ar_hha": "حاءْ", "ar_kha": "خاءْ", "ar_dal": "دالْ",
    "ar_dhal": "ذالْ", "ar_ra": "راءْ", "ar_zay": "زايْ", "ar_sin": "سينْ",
    "ar_shin": "شينْ", "ar_sad": "صادْ", "ar_dad": "ضادْ", "ar_tta": "طاءْ",
    "ar_zza": "ظاءْ", "ar_ain": "عَيْنْ", "ar_ghain": "غَيْنْ",
    "ar_fa": "فاءْ", "ar_qaf": "قافْ", "ar_kaf": "كافْ", "ar_lam": "لامْ",
    "ar_mim": "ميمْ", "ar_nun": "نونْ", "ar_ha": "هاءْ", "ar_waw": "واوْ",
    "ar_ya": "ياءْ",
}

for i, (en_word, ar_word) in enumerate(zip(EN_NUMBERS, AR_NUMBERS), start=1):
    EN[f"count_{en_word}"] = f"{en_word.capitalize()}!"
    AR[f"count_{en_word}"] = f"{ar_word}!"

for code in range(ord("a"), ord("z") + 1):
    letter = chr(code)
    EN[f"letter_{letter}"] = f"{letter.upper()}!"
    AR[f"letter_{letter}"] = None  # synthesized with the EN voice

for file_id, name in AR_LETTER_NAMES.items():
    AR[file_id] = f"{name}!"
    EN[file_id] = None  # synthesized with the AR voice


# ---------------------------------------------------------------- backends

class PiperBackend:
    def __init__(self):
        from piper import PiperVoice  # noqa: import checked by caller
        self.voices = {}
        for lang, model in PIPER_MODELS.items():
            path = os.path.join(MODEL_DIR, model)
            if not os.path.exists(path):
                raise FileNotFoundError(path)
            self.voices[lang] = PiperVoice.load(path)

    def synth_wav(self, lang, text, wav_path):
        import piper
        voice = self.voices[lang]
        kwargs = {}
        try:
            syn_config = piper.SynthesisConfig(
                length_scale=PIPER_LENGTH_SCALE[lang])
            kwargs["syn_config"] = syn_config
        except AttributeError:
            pass
        with wave.open(wav_path, "wb") as wav_file:
            voice.synthesize_wav(text, wav_file, **kwargs)


class EspeakBackend:
    def synth_wav(self, lang, text, wav_path):
        subprocess.run(
            ["espeak-ng", *ESPEAK_VOICE[lang], "-w", wav_path, text],
            check=True, capture_output=True,
        )


def to_ogg(wav_path, ogg_path):
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
         "-c:a", "libvorbis", "-q:a", "2", "-ar", "22050", ogg_path],
        check=True, capture_output=True,
    )


def enum_ids():
    path = os.path.join(ROOT, "lib", "core", "audio", "voice_catalog.dart")
    with open(path) as f:
        src = f.read()
    body = re.search(r"enum VoiceInstruction \{(.*?)\}", src, re.S).group(1)
    body = re.sub(r"//[^\n]*", "", body)
    names = re.findall(r"\b([a-zA-Z][a-zA-Z0-9]*)\s*,", body)
    return [re.sub(r"([A-Z])", lambda m: "_" + m.group(1).lower(), n)
            for n in names]


def main():
    ids = enum_ids()
    missing = [i for i in ids if i not in EN or i not in AR]
    if missing:
        sys.exit(f"Missing speech text for: {missing}")

    try:
        backend = PiperBackend()
        print("backend: piper (neural)")
    except Exception as e:  # noqa: BLE001 - fall back to espeak on any issue
        print(f"backend: espeak-ng fallback ({e})")
        backend = EspeakBackend()

    for lang, catalog in (("en", EN), ("ar", AR)):
        out_dir = os.path.join(VOICES_DIR, lang)
        os.makedirs(out_dir, exist_ok=True)
        for file_id in ids:
            text = catalog[file_id]
            # Cross-language content keeps its own voice.
            voice_lang = lang
            if text is None:
                if file_id.startswith("ar_"):
                    text, voice_lang = AR[file_id], "ar"
                else:
                    text, voice_lang = EN[file_id], "en"
            with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
                backend.synth_wav(voice_lang, text, tmp.name)
                to_ogg(tmp.name, os.path.join(out_dir, f"{file_id}.ogg"))
        print(f"voices {lang}: {len(ids)} spoken clips")


if __name__ == "__main__":
    main()
