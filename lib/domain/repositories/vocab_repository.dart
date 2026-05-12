import '../entities/vocab.dart';

/// Abstract interface for Vocab data operations.
/// This is the "Port" in Hexagonal Architecture.
abstract class VocabRepository {
  /// Fetches all stored vocabularies.
  Future<List<Vocab>> getAllVocabs();

  /// Saves or Updates a vocabulary entry.
  Future<void> saveVocab(Vocab vocab);

  /// Deletes a specific vocabulary by its ID.
  Future<void> deleteVocab(int id);

  /// Finds a specific word to check for duplicates.
  Future<Vocab?> findByWord(String word);

  /// Retrieves a single vocabulary entry by its unique identifier.
  Future<Vocab?> getById(int id);

  /// Fetches vocabularies within a specific ID range (e.g., from ID x to y).
  Future<List<Vocab>> getVocabsInRange(int startId, int endId);

  /// Fetches vocabularies that are due for learning/review.
  Future<List<Vocab>> getWhereLearned({
    required bool isLearned,
    int limit = 20,
    int offset = 0,
    bool newestFirst = true,
  });

  /// Fetches a paginated list of vocabularies without filtering by learned status.
  Future<List<Vocab>> getMany({
    int limit = 20,
    int offset = 0,
  });

  /// Counts the total number of vocabularies, optionally filtered by learned status.
  Future<int> countFilteredVocabs({int? learnedStatus});
}