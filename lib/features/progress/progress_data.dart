import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';
import '../../shared/models/game_id.dart';
import '../../shared/models/skill.dart';
import '../../shared/models/subject.dart';

/// Neutral play statistics for one mini-game.
///
/// These numbers exist so parents can see what their child enjoys; they are
/// never used to grade the child.
class GameProgress {
  const GameProgress({
    this.attempts = 0,
    this.completions = 0,
    this.completionsWithoutHints = 0,
    this.hintsShown = 0,
    this.playMs = 0,
  });

  final int attempts;
  final int completions;
  final int completionsWithoutHints;
  final int hintsShown;
  final int playMs;

  GameProgress copyWith({
    int? attempts,
    int? completions,
    int? completionsWithoutHints,
    int? hintsShown,
    int? playMs,
  }) =>
      GameProgress(
        attempts: attempts ?? this.attempts,
        completions: completions ?? this.completions,
        completionsWithoutHints:
            completionsWithoutHints ?? this.completionsWithoutHints,
        hintsShown: hintsShown ?? this.hintsShown,
        playMs: playMs ?? this.playMs,
      );

  Map<String, dynamic> toJson() => {
        'attempts': attempts,
        'completions': completions,
        'completionsWithoutHints': completionsWithoutHints,
        'hintsShown': hintsShown,
        'playMs': playMs,
      };

  factory GameProgress.fromJson(Map<String, dynamic> json) => GameProgress(
        attempts: json['attempts'] as int? ?? 0,
        completions: json['completions'] as int? ?? 0,
        completionsWithoutHints: json['completionsWithoutHints'] as int? ?? 0,
        hintsShown: json['hintsShown'] as int? ?? 0,
        playMs: json['playMs'] as int? ?? 0,
      );
}

/// All locally tracked progress.
class ProgressData {
  ProgressData({
    Map<GameId, GameProgress>? games,
    Map<Subject, GameProgress>? subjects,
    Map<Skill, int>? skillPlays,
    this.relaxedCompletionStreak = 0,
  })  : games = games ?? {},
        subjects = subjects ?? {},
        skillPlays = skillPlays ?? {};

  final Map<GameId, GameProgress> games;

  /// Academy activity statistics per concept area (v2).
  final Map<Subject, GameProgress> subjects;

  /// How often each skill was part of a completed activity.
  final Map<Skill, int> skillPlays;

  /// Completions without hints since the last stage change, across sessions.
  /// Used by gentle automatic stage progression (never speed-based).
  final int relaxedCompletionStreak;

  GameProgress of(GameId id) => games[id] ?? const GameProgress();

  GameProgress ofSubject(Subject subject) =>
      subjects[subject] ?? const GameProgress();

  Iterable<GameProgress> get _all =>
      [...games.values, ...subjects.values];

  int get totalPlayMs => _all.fold(0, (sum, g) => sum + g.playMs);

  int get totalAttempts => _all.fold(0, (sum, g) => sum + g.attempts);

  int get totalCompletions => _all.fold(0, (sum, g) => sum + g.completions);

  int get totalHintsShown => _all.fold(0, (sum, g) => sum + g.hintsShown);

  /// Games ordered by how often the child chose them (most first).
  List<GameId> get favourites {
    final entries = games.entries.where((e) => e.value.attempts > 0).toList()
      ..sort((a, b) => b.value.attempts.compareTo(a.value.attempts));
    return [for (final e in entries) e.key];
  }

  List<Skill> get practisedSkills {
    final entries = skillPlays.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries) e.key];
  }

  ProgressData copyWith({
    Map<GameId, GameProgress>? games,
    Map<Subject, GameProgress>? subjects,
    Map<Skill, int>? skillPlays,
    int? relaxedCompletionStreak,
  }) =>
      ProgressData(
        games: games ?? this.games,
        subjects: subjects ?? this.subjects,
        skillPlays: skillPlays ?? this.skillPlays,
        relaxedCompletionStreak:
            relaxedCompletionStreak ?? this.relaxedCompletionStreak,
      );

  Map<String, dynamic> toJson() => {
        'games': {
          for (final e in games.entries) e.key.storageKey: e.value.toJson(),
        },
        'subjects': {
          for (final e in subjects.entries) e.key.storageKey: e.value.toJson(),
        },
        'skillPlays': {
          for (final e in skillPlays.entries) e.key.storageKey: e.value,
        },
        'relaxedCompletionStreak': relaxedCompletionStreak,
      };

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    final gamesRaw = (json['games'] as Map?)?.cast<String, dynamic>() ?? {};
    final subjectsRaw =
        (json['subjects'] as Map?)?.cast<String, dynamic>() ?? {};
    final skillsRaw =
        (json['skillPlays'] as Map?)?.cast<String, dynamic>() ?? {};
    return ProgressData(
      games: {
        for (final e in gamesRaw.entries)
          if (GameId.fromStorageKey(e.key) != null)
            GameId.fromStorageKey(e.key)!: GameProgress.fromJson(
              (e.value as Map).cast<String, dynamic>(),
            ),
      },
      subjects: {
        for (final e in subjectsRaw.entries)
          if (Subject.fromStorageKey(e.key) != null)
            Subject.fromStorageKey(e.key)!: GameProgress.fromJson(
              (e.value as Map).cast<String, dynamic>(),
            ),
      },
      skillPlays: {
        for (final e in skillsRaw.entries)
          if (Skill.fromStorageKey(e.key) != null)
            Skill.fromStorageKey(e.key)!: e.value as int? ?? 0,
      },
      relaxedCompletionStreak: json['relaxedCompletionStreak'] as int? ?? 0,
    );
  }
}

class ProgressRepository {
  ProgressRepository(LocalStore store)
      : _doc = JsonDocument<ProgressData>(
          store: store,
          storeKey: 'progress',
          decode: ProgressData.fromJson,
          encode: (p) => p.toJson(),
          fallback: ProgressData.new,
        );

  final JsonDocument<ProgressData> _doc;

  Future<ProgressData> load() => _doc.load();
  Future<void> save(ProgressData data) => _doc.save(data);
  Future<void> clear() => _doc.clear();
}
