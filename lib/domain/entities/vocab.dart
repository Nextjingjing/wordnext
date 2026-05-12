/// Represents the core Vocabulary object in the system.
/// This class is a "Plain Old Dart Object" and has no dependencies on SQLite.
class Vocab {
  final int? id;
  final String word;
  final String translated;
  final String partOfSpeech;
  final String definitionEn;
  final String exampleSentence;
  final int strength;
  final DateTime lastReview;
  bool isLearned;

  Vocab({
    this.id,
    required this.word,
    required this.translated,
    required this.partOfSpeech,
    required this.definitionEn,
    required this.exampleSentence,
    required this.strength,
    required this.lastReview,
    required this.isLearned,
  });

  /// Business Logic: Increases the recall strength of the word.
  /// Returns a new instance to maintain Immutability.
  Vocab increaseStrength() {
    return copyWith(strength: strength + 1, lastReview: DateTime.now());
  }

  /// Business Logic: Decreases the recall strength, ensuring it never goes below 0.
  Vocab decreaseStrength() {
    return copyWith(
      strength: strength > 0 ? strength - 1 : 0,
      lastReview: DateTime.now(),
    );
  }

  /// Helper method to create a modified copy of the entity.
  /// Useful for state management and updating immutable data.
  Vocab copyWith({
    int? id,
    String? word,
    String? translated,
    String? partOfSpeech,
    String? definitionEn,
    String? exampleSentence,
    int? strength,
    DateTime? lastReview,
    bool? isLearned,
  }) {
    return Vocab(
      id: id ?? this.id,
      word: word ?? this.word,
      translated: translated ?? this.translated,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definitionEn: definitionEn ?? this.definitionEn,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      strength: strength ?? this.strength,
      lastReview: lastReview ?? this.lastReview,
      isLearned: isLearned ?? this.isLearned,
    );
  }
}
