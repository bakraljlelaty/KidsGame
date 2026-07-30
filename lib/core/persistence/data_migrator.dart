/// Upgrades persisted JSON documents from older schema versions to the
/// current one (AppConfig.dataSchemaVersion).
///
/// The MVP ships schema version 1, so there is nothing to migrate yet, but
/// the pipeline is in place: when the schema changes, bump
/// `AppConfig.dataSchemaVersion` and add a step in [migrate] transforming
/// `fromVersion` -> `fromVersion + 1` for the affected [storeKey]s.
class DataMigrator {
  DataMigrator._();

  static Map<String, dynamic> migrate(
    String storeKey,
    Map<String, dynamic> data,
    int fromVersion,
  ) {
    var current = data;
    var version = fromVersion;
    while (version < _latest) {
      current = _step(storeKey, current, version);
      version += 1;
    }
    return current;
  }

  static const int _latest = 2;

  static Map<String, dynamic> _step(
    String storeKey,
    Map<String, dynamic> data,
    int fromVersion,
  ) {
    switch (fromVersion) {
      case 1:
        // v1 -> v2: the academy AgeBand replaces the v1 development stage
        // and approximate age group on the profile document.
        if (storeKey == 'profile' && data['band'] == null) {
          final stage = data['stage'] as String?;
          final ageGroup = data['ageGroup'] as String?;
          data['band'] = switch (stage) {
            'helper' => 'three_four',
            'little_thinker' => 'four_five',
            _ => ageGroup == 'around_three' ? 'three_four' : 'two_three',
          };
          data.remove('stage');
          data.remove('ageGroup');
        }
        return data;
      default:
        return data;
    }
  }
}
