/// The academy's concept areas. Each subject room offers 5–8 activities
/// (instantiated from the reusable engines) tuned to the child's age band,
/// in both English and Arabic. Milo's World hosts the six bespoke v1
/// mini-games.
enum Subject {
  colors('colors'),
  shapes('shapes'),
  animals('animals'),
  food('food'),
  numbers('numbers'),
  letters('letters'),
  milosWorld('milos_world');

  const Subject(this.storageKey);

  final String storageKey;

  static Subject? fromStorageKey(String key) {
    for (final s in Subject.values) {
      if (s.storageKey == key) return s;
    }
    return null;
  }
}
