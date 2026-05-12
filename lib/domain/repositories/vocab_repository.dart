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
}