/// Skills a mini-game lets the child practise. Shown to parents with
/// neutral wording; never used for scoring or assessment.
enum Skill {
  tapping('tapping'),
  dragging('dragging'),
  swiping('swiping'),
  matching('matching'),
  colors('colors'),
  shapes('shapes'),
  counting('counting'),
  sequencing('sequencing'),
  routines('routines'),
  attention('attention'),
  animals('animals'),
  spatial('spatial'),
  fineMotor('fine_motor');

  const Skill(this.storageKey);

  final String storageKey;

  static Skill? fromStorageKey(String key) {
    for (final s in Skill.values) {
      if (s.storageKey == key) return s;
    }
    return null;
  }
}
