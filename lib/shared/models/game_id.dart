/// Stable identifiers for the six MVP mini-games.
///
/// The [storageKey] is persisted in local data; never rename existing keys
/// without adding a migration in DataMigrator.
enum GameId {
  feedAnimals('feed_animals'),
  bubblePop('bubble_pop'),
  dancingSocks('dancing_socks'),
  muddyPig('muddy_pig'),
  buildRocket('build_rocket'),
  bedtimeRoutine('bedtime_routine');

  const GameId(this.storageKey);

  final String storageKey;

  static GameId? fromStorageKey(String key) {
    for (final id in GameId.values) {
      if (id.storageKey == key) return id;
    }
    return null;
  }
}
