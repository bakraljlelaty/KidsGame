/// Identifiers for every spoken instruction in the game.
///
/// Voice audio is resolved as `assets/audio/voices/<lang>/<id>.wav`, so
/// replacing the generated development placeholders with real recordings is
/// just a file drop — no code changes. Text shown to parents lives in the
/// ARB files, deliberately separate from these audio identifiers.
enum VoiceInstruction {
  // General / Milo
  welcome,
  chooseGame,
  greatJob,
  wellDone,
  tryAgain,
  stickerEarned,
  sessionOver,
  goodNight,

  // Counting
  countOne,
  countTwo,
  countThree,

  // Feed the Animals
  feedIntro,
  feedRabbit,
  feedCow,
  feedMonkey,

  // Bubble Pop
  bubbleIntro,
  popBlue,
  popYellow,
  popRed,
  popGreen,
  popFish,
  popStar,
  popHeart,
  popThenNext,

  // Dancing Socks
  socksIntro,
  socksFind,

  // Muddy Pig Bath
  pigIntro,
  pigScrub,
  pigRinse,
  pigDry,
  pigClean,

  // Build the Rocket
  rocketIntro,
  rocketPiece,
  rocketLaunch,

  // Bedtime Routine
  bedtimeIntro,
  bedtimeToys,
  bedtimeTeeth,
  bedtimePajamas,
  bedtimeTeddy,
  bedtimeLight,
  bedtimeDone,

  // ---- Academy (v2) ----

  // Engine prompts
  findIt,
  sortIntro,
  sortNext,
  shadowIntro,
  shadowNext,
  memoryIntro,
  memoryPairFound,
  patternIntro,
  patternNext,
  countIntro,
  giveMe,
  traceIntro,
  traceFollow,
  unitDone,
  pathIntro,
  roomsIntro,
  levelUp,

  // Colors
  colorRed,
  colorBlue,
  colorYellow,
  colorGreen,
  colorOrange,
  colorPurple,
  colorPink,

  // Shapes
  shapeCircle,
  shapeSquare,
  shapeTriangle,
  shapeStar,
  shapeHeart,
  shapeRectangle,
  shapeOval,
  shapeDiamond,

  // Numbers four..ten (one..three exist above)
  countFour,
  countFive,
  countSix,
  countSeven,
  countEight,
  countNine,
  countTen,

  // English letters
  letterA, letterB, letterC, letterD, letterE, letterF, letterG,
  letterH, letterI, letterJ, letterK, letterL, letterM, letterN,
  letterO, letterP, letterQ, letterR, letterS, letterT, letterU,
  letterV, letterW, letterX, letterY, letterZ,

  // Arabic letters
  arAlif, arBa, arTa, arTha, arJim, arHha, arKha, arDal, arDhal,
  arRa, arZay, arSin, arShin, arSad, arDad, arTta, arZza, arAin,
  arGhain, arFa, arQaf, arKaf, arLam, arMim, arNun, arHa, arWaw,
  arYa,

  // Item names: animals
  nameRabbit, nameCow, nameMonkey, nameDuck, nameFish,
  nameCat, nameDog, nameBee, nameButterfly, nameLadybug,

  // Item names: food
  nameApple, nameBanana, nameStrawberry, nameOrange, namePear,
  nameGrapes, nameBread, nameMilk, nameCheese, nameEgg,
  nameCarrot, nameCookie,
}

class VoiceCatalog {
  VoiceCatalog._();

  static const supportedLanguages = ['en', 'ar'];

  /// snake_case file id for an instruction.
  static String fileId(VoiceInstruction instruction) {
    final name = instruction.name;
    final buffer = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      final ch = name[i];
      if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
        buffer.write('_${ch.toLowerCase()}');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  /// Asset path (relative to the assets/ audio root used by audioplayers).
  static String assetPath(VoiceInstruction instruction, String languageCode) {
    final lang = supportedLanguages.contains(languageCode)
        ? languageCode
        : supportedLanguages.first;
    return 'audio/voices/$lang/${fileId(instruction)}.wav';
  }
}
