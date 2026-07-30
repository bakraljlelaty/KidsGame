import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import 'content_item.dart';

/// All teachable content, organised into named packs that ActivitySpecs
/// reference via `contentPack`. Adding content = adding data here (plus a
/// painter in ItemArt when a new artId appears).
class ItemCatalog {
  ItemCatalog._();

  static const List<ContentItem> colors = [
    ContentItem(id: 'color_red', artId: 'blob', color: Palette.softRed, nameVoice: VoiceInstruction.colorRed, group: 'color'),
    ContentItem(id: 'color_blue', artId: 'blob', color: Palette.softBlue, nameVoice: VoiceInstruction.colorBlue, group: 'color'),
    ContentItem(id: 'color_yellow', artId: 'blob', color: Palette.softYellow, nameVoice: VoiceInstruction.colorYellow, group: 'color'),
    ContentItem(id: 'color_green', artId: 'blob', color: Palette.softGreen, nameVoice: VoiceInstruction.colorGreen, group: 'color'),
    ContentItem(id: 'color_orange', artId: 'blob', color: Palette.softOrange, nameVoice: VoiceInstruction.colorOrange, group: 'color'),
    ContentItem(id: 'color_purple', artId: 'blob', color: Palette.softPurple, nameVoice: VoiceInstruction.colorPurple, group: 'color'),
    ContentItem(id: 'color_pink', artId: 'blob', color: Palette.softPink, nameVoice: VoiceInstruction.colorPink, group: 'color'),
  ];

  static const List<ContentItem> shapes = [
    ContentItem(id: 'shape_circle', color: Palette.softBlue, nameVoice: VoiceInstruction.shapeCircle, group: 'shape'),
    ContentItem(id: 'shape_square', color: Palette.softRed, nameVoice: VoiceInstruction.shapeSquare, group: 'shape'),
    ContentItem(id: 'shape_triangle', color: Palette.softGreen, nameVoice: VoiceInstruction.shapeTriangle, group: 'shape'),
    ContentItem(id: 'shape_star', color: Palette.starGold, nameVoice: VoiceInstruction.shapeStar, group: 'shape'),
    ContentItem(id: 'shape_heart', color: Palette.softPink, nameVoice: VoiceInstruction.shapeHeart, group: 'shape'),
    ContentItem(id: 'shape_rectangle', color: Palette.softOrange, nameVoice: VoiceInstruction.shapeRectangle, group: 'shape'),
    ContentItem(id: 'shape_oval', color: Palette.softPurple, nameVoice: VoiceInstruction.shapeOval, group: 'shape'),
    ContentItem(id: 'shape_diamond', color: Palette.babyBlue, nameVoice: VoiceInstruction.shapeDiamond, group: 'shape'),
  ];

  static const List<ContentItem> numbers = [
    ContentItem(id: 'num_1', artId: 'glyph', glyph: '1', value: 1, color: Palette.softRed, nameVoice: VoiceInstruction.countOne, group: 'number'),
    ContentItem(id: 'num_2', artId: 'glyph', glyph: '2', value: 2, color: Palette.softBlue, nameVoice: VoiceInstruction.countTwo, group: 'number'),
    ContentItem(id: 'num_3', artId: 'glyph', glyph: '3', value: 3, color: Palette.softGreen, nameVoice: VoiceInstruction.countThree, group: 'number'),
    ContentItem(id: 'num_4', artId: 'glyph', glyph: '4', value: 4, color: Palette.softOrange, nameVoice: VoiceInstruction.countFour, group: 'number'),
    ContentItem(id: 'num_5', artId: 'glyph', glyph: '5', value: 5, color: Palette.softPurple, nameVoice: VoiceInstruction.countFive, group: 'number'),
    ContentItem(id: 'num_6', artId: 'glyph', glyph: '6', value: 6, color: Palette.softPink, nameVoice: VoiceInstruction.countSix, group: 'number'),
    ContentItem(id: 'num_7', artId: 'glyph', glyph: '7', value: 7, color: Palette.babyBlue, nameVoice: VoiceInstruction.countSeven, group: 'number'),
    ContentItem(id: 'num_8', artId: 'glyph', glyph: '8', value: 8, color: Palette.softBrown, nameVoice: VoiceInstruction.countEight, group: 'number'),
    ContentItem(id: 'num_9', artId: 'glyph', glyph: '9', value: 9, color: Palette.softRed, nameVoice: VoiceInstruction.countNine, group: 'number'),
    ContentItem(id: 'num_10', artId: 'glyph', glyph: '10', value: 10, color: Palette.softBlue, nameVoice: VoiceInstruction.countTen, group: 'number'),
  ];

  static const List<ContentItem> lettersEn = [
    ContentItem(id: 'letter_a', artId: 'glyph', glyph: 'A', color: Palette.softRed, nameVoice: VoiceInstruction.letterA, group: 'letter'),
    ContentItem(id: 'letter_b', artId: 'glyph', glyph: 'B', color: Palette.softBlue, nameVoice: VoiceInstruction.letterB, group: 'letter'),
    ContentItem(id: 'letter_c', artId: 'glyph', glyph: 'C', color: Palette.softGreen, nameVoice: VoiceInstruction.letterC, group: 'letter'),
    ContentItem(id: 'letter_d', artId: 'glyph', glyph: 'D', color: Palette.softOrange, nameVoice: VoiceInstruction.letterD, group: 'letter'),
    ContentItem(id: 'letter_e', artId: 'glyph', glyph: 'E', color: Palette.softPurple, nameVoice: VoiceInstruction.letterE, group: 'letter'),
    ContentItem(id: 'letter_f', artId: 'glyph', glyph: 'F', color: Palette.softPink, nameVoice: VoiceInstruction.letterF, group: 'letter'),
    ContentItem(id: 'letter_g', artId: 'glyph', glyph: 'G', color: Palette.babyBlue, nameVoice: VoiceInstruction.letterG, group: 'letter'),
    ContentItem(id: 'letter_h', artId: 'glyph', glyph: 'H', color: Palette.softRed, nameVoice: VoiceInstruction.letterH, group: 'letter'),
    ContentItem(id: 'letter_i', artId: 'glyph', glyph: 'I', color: Palette.softBlue, nameVoice: VoiceInstruction.letterI, group: 'letter'),
    ContentItem(id: 'letter_j', artId: 'glyph', glyph: 'J', color: Palette.softGreen, nameVoice: VoiceInstruction.letterJ, group: 'letter'),
    ContentItem(id: 'letter_k', artId: 'glyph', glyph: 'K', color: Palette.softOrange, nameVoice: VoiceInstruction.letterK, group: 'letter'),
    ContentItem(id: 'letter_l', artId: 'glyph', glyph: 'L', color: Palette.softPurple, nameVoice: VoiceInstruction.letterL, group: 'letter'),
    ContentItem(id: 'letter_m', artId: 'glyph', glyph: 'M', color: Palette.softPink, nameVoice: VoiceInstruction.letterM, group: 'letter'),
    ContentItem(id: 'letter_n', artId: 'glyph', glyph: 'N', color: Palette.babyBlue, nameVoice: VoiceInstruction.letterN, group: 'letter'),
    ContentItem(id: 'letter_o', artId: 'glyph', glyph: 'O', color: Palette.softRed, nameVoice: VoiceInstruction.letterO, group: 'letter'),
    ContentItem(id: 'letter_p', artId: 'glyph', glyph: 'P', color: Palette.softBlue, nameVoice: VoiceInstruction.letterP, group: 'letter'),
    ContentItem(id: 'letter_q', artId: 'glyph', glyph: 'Q', color: Palette.softGreen, nameVoice: VoiceInstruction.letterQ, group: 'letter'),
    ContentItem(id: 'letter_r', artId: 'glyph', glyph: 'R', color: Palette.softOrange, nameVoice: VoiceInstruction.letterR, group: 'letter'),
    ContentItem(id: 'letter_s', artId: 'glyph', glyph: 'S', color: Palette.softPurple, nameVoice: VoiceInstruction.letterS, group: 'letter'),
    ContentItem(id: 'letter_t', artId: 'glyph', glyph: 'T', color: Palette.softPink, nameVoice: VoiceInstruction.letterT, group: 'letter'),
    ContentItem(id: 'letter_u', artId: 'glyph', glyph: 'U', color: Palette.babyBlue, nameVoice: VoiceInstruction.letterU, group: 'letter'),
    ContentItem(id: 'letter_v', artId: 'glyph', glyph: 'V', color: Palette.softRed, nameVoice: VoiceInstruction.letterV, group: 'letter'),
    ContentItem(id: 'letter_w', artId: 'glyph', glyph: 'W', color: Palette.softBlue, nameVoice: VoiceInstruction.letterW, group: 'letter'),
    ContentItem(id: 'letter_x', artId: 'glyph', glyph: 'X', color: Palette.softGreen, nameVoice: VoiceInstruction.letterX, group: 'letter'),
    ContentItem(id: 'letter_y', artId: 'glyph', glyph: 'Y', color: Palette.softOrange, nameVoice: VoiceInstruction.letterY, group: 'letter'),
    ContentItem(id: 'letter_z', artId: 'glyph', glyph: 'Z', color: Palette.softPurple, nameVoice: VoiceInstruction.letterZ, group: 'letter'),
  ];

  static const List<ContentItem> lettersAr = [
    ContentItem(id: 'ar_alif', artId: 'glyph', glyph: 'ا', color: Palette.softRed, nameVoice: VoiceInstruction.arAlif, group: 'letter'),
    ContentItem(id: 'ar_ba', artId: 'glyph', glyph: 'ب', color: Palette.softBlue, nameVoice: VoiceInstruction.arBa, group: 'letter'),
    ContentItem(id: 'ar_ta', artId: 'glyph', glyph: 'ت', color: Palette.softGreen, nameVoice: VoiceInstruction.arTa, group: 'letter'),
    ContentItem(id: 'ar_tha', artId: 'glyph', glyph: 'ث', color: Palette.softOrange, nameVoice: VoiceInstruction.arTha, group: 'letter'),
    ContentItem(id: 'ar_jim', artId: 'glyph', glyph: 'ج', color: Palette.softPurple, nameVoice: VoiceInstruction.arJim, group: 'letter'),
    ContentItem(id: 'ar_hha', artId: 'glyph', glyph: 'ح', color: Palette.softPink, nameVoice: VoiceInstruction.arHha, group: 'letter'),
    ContentItem(id: 'ar_kha', artId: 'glyph', glyph: 'خ', color: Palette.babyBlue, nameVoice: VoiceInstruction.arKha, group: 'letter'),
    ContentItem(id: 'ar_dal', artId: 'glyph', glyph: 'د', color: Palette.softRed, nameVoice: VoiceInstruction.arDal, group: 'letter'),
    ContentItem(id: 'ar_dhal', artId: 'glyph', glyph: 'ذ', color: Palette.softBlue, nameVoice: VoiceInstruction.arDhal, group: 'letter'),
    ContentItem(id: 'ar_ra', artId: 'glyph', glyph: 'ر', color: Palette.softGreen, nameVoice: VoiceInstruction.arRa, group: 'letter'),
    ContentItem(id: 'ar_zay', artId: 'glyph', glyph: 'ز', color: Palette.softOrange, nameVoice: VoiceInstruction.arZay, group: 'letter'),
    ContentItem(id: 'ar_sin', artId: 'glyph', glyph: 'س', color: Palette.softPurple, nameVoice: VoiceInstruction.arSin, group: 'letter'),
    ContentItem(id: 'ar_shin', artId: 'glyph', glyph: 'ش', color: Palette.softPink, nameVoice: VoiceInstruction.arShin, group: 'letter'),
    ContentItem(id: 'ar_sad', artId: 'glyph', glyph: 'ص', color: Palette.babyBlue, nameVoice: VoiceInstruction.arSad, group: 'letter'),
    ContentItem(id: 'ar_dad', artId: 'glyph', glyph: 'ض', color: Palette.softRed, nameVoice: VoiceInstruction.arDad, group: 'letter'),
    ContentItem(id: 'ar_tta', artId: 'glyph', glyph: 'ط', color: Palette.softBlue, nameVoice: VoiceInstruction.arTta, group: 'letter'),
    ContentItem(id: 'ar_zza', artId: 'glyph', glyph: 'ظ', color: Palette.softGreen, nameVoice: VoiceInstruction.arZza, group: 'letter'),
    ContentItem(id: 'ar_ain', artId: 'glyph', glyph: 'ع', color: Palette.softOrange, nameVoice: VoiceInstruction.arAin, group: 'letter'),
    ContentItem(id: 'ar_ghain', artId: 'glyph', glyph: 'غ', color: Palette.softPurple, nameVoice: VoiceInstruction.arGhain, group: 'letter'),
    ContentItem(id: 'ar_fa', artId: 'glyph', glyph: 'ف', color: Palette.softPink, nameVoice: VoiceInstruction.arFa, group: 'letter'),
    ContentItem(id: 'ar_qaf', artId: 'glyph', glyph: 'ق', color: Palette.babyBlue, nameVoice: VoiceInstruction.arQaf, group: 'letter'),
    ContentItem(id: 'ar_kaf', artId: 'glyph', glyph: 'ك', color: Palette.softRed, nameVoice: VoiceInstruction.arKaf, group: 'letter'),
    ContentItem(id: 'ar_lam', artId: 'glyph', glyph: 'ل', color: Palette.softBlue, nameVoice: VoiceInstruction.arLam, group: 'letter'),
    ContentItem(id: 'ar_mim', artId: 'glyph', glyph: 'م', color: Palette.softGreen, nameVoice: VoiceInstruction.arMim, group: 'letter'),
    ContentItem(id: 'ar_nun', artId: 'glyph', glyph: 'ن', color: Palette.softOrange, nameVoice: VoiceInstruction.arNun, group: 'letter'),
    ContentItem(id: 'ar_ha', artId: 'glyph', glyph: 'ه', color: Palette.softPurple, nameVoice: VoiceInstruction.arHa, group: 'letter'),
    ContentItem(id: 'ar_waw', artId: 'glyph', glyph: 'و', color: Palette.softPink, nameVoice: VoiceInstruction.arWaw, group: 'letter'),
    ContentItem(id: 'ar_ya', artId: 'glyph', glyph: 'ي', color: Palette.babyBlue, nameVoice: VoiceInstruction.arYa, group: 'letter'),
  ];

  /// Animals with sortable habitat groups (farm / pet / water / garden).
  static const List<ContentItem> animals = [
    ContentItem(id: 'animal_rabbit', group: 'farm', nameVoice: VoiceInstruction.nameRabbit),
    ContentItem(id: 'animal_cow', group: 'farm', nameVoice: VoiceInstruction.nameCow),
    ContentItem(id: 'animal_monkey', group: 'farm', nameVoice: VoiceInstruction.nameMonkey),
    ContentItem(id: 'animal_duck', group: 'water', nameVoice: VoiceInstruction.nameDuck),
    ContentItem(id: 'animal_fish', group: 'water', nameVoice: VoiceInstruction.nameFish),
    ContentItem(id: 'animal_cat', group: 'pet', nameVoice: VoiceInstruction.nameCat),
    ContentItem(id: 'animal_dog', group: 'pet', nameVoice: VoiceInstruction.nameDog),
    ContentItem(id: 'animal_bee', group: 'garden', nameVoice: VoiceInstruction.nameBee),
    ContentItem(id: 'animal_butterfly', group: 'garden', nameVoice: VoiceInstruction.nameButterfly),
    ContentItem(id: 'animal_ladybug', group: 'garden', nameVoice: VoiceInstruction.nameLadybug),
  ];

  /// Food with sortable groups (fruit / other food).
  static const List<ContentItem> food = [
    ContentItem(id: 'food_apple', group: 'fruit', nameVoice: VoiceInstruction.nameApple),
    ContentItem(id: 'food_banana', group: 'fruit', nameVoice: VoiceInstruction.nameBanana),
    ContentItem(id: 'food_strawberry', group: 'fruit', nameVoice: VoiceInstruction.nameStrawberry),
    ContentItem(id: 'food_orange', group: 'fruit', nameVoice: VoiceInstruction.nameOrange),
    ContentItem(id: 'food_pear', group: 'fruit', nameVoice: VoiceInstruction.namePear),
    ContentItem(id: 'food_grapes', group: 'fruit', nameVoice: VoiceInstruction.nameGrapes),
    ContentItem(id: 'food_bread', group: 'meal', nameVoice: VoiceInstruction.nameBread),
    ContentItem(id: 'food_milk', group: 'meal', nameVoice: VoiceInstruction.nameMilk),
    ContentItem(id: 'food_cheese', group: 'meal', nameVoice: VoiceInstruction.nameCheese),
    ContentItem(id: 'food_egg', group: 'meal', nameVoice: VoiceInstruction.nameEgg),
    ContentItem(id: 'food_carrot', group: 'meal', nameVoice: VoiceInstruction.nameCarrot),
    ContentItem(id: 'food_cookie', group: 'meal', nameVoice: VoiceInstruction.nameCookie),
  ];

  static const List<ContentItem> vehicles = [
    ContentItem(id: 'vehicle_car', group: 'vehicle'),
    ContentItem(id: 'vehicle_bus', group: 'vehicle'),
    ContentItem(id: 'vehicle_boat', group: 'vehicle'),
    ContentItem(id: 'vehicle_rocket', group: 'vehicle'),
  ];

  static const List<ContentItem> toys = [
    ContentItem(id: 'toy_ball', group: 'toy'),
    ContentItem(id: 'toy_block', group: 'toy'),
    ContentItem(id: 'toy_teddy', group: 'toy'),
    ContentItem(id: 'toy_drum', group: 'toy'),
    ContentItem(id: 'toy_train', group: 'toy'),
  ];

  static const Map<String, List<ContentItem>> packs = {
    'colors': colors,
    'shapes': shapes,
    'numbers': numbers,
    'letters_en': lettersEn,
    'letters_ar': lettersAr,
    'animals': animals,
    'food': food,
    'vehicles': vehicles,
    'toys': toys,
  };

  /// Pack lookup; unknown names return an empty list (engines fall back
  /// gracefully rather than crash a child's session).
  static List<ContentItem> pack(String name) => packs[name] ?? const [];

  /// 'letters' resolves per app language.
  static List<ContentItem> lettersFor(String languageCode) =>
      languageCode == 'ar' ? lettersAr : lettersEn;

  static ContentItem? byId(String id) {
    for (final packItems in packs.values) {
      for (final item in packItems) {
        if (item.id == id) return item;
      }
    }
    return null;
  }
}
