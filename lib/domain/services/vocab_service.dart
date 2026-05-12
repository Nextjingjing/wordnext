import 'dart:math';
import '../entities/vocab.dart';
import '../repositories/vocab_repository.dart';

/// Application Service that handles vocabulary business logic.
class VocabService {
  final VocabRepository _repository;
  final Random _random = Random();

  VocabService(this._repository);

  // ----------------------------------------------------------------------
  // BASIC OPERATIONS
  // ----------------------------------------------------------------------

  /// Retrieves a vocabulary by its unique ID.
  Future<Vocab?> getVocabById(int id) async {
    return await _repository.getById(id);
  }

  /// Retrieves a range of vocabularies for list views or pagination.
  Future<List<Vocab>> getVocabByRangeId(int startId, int endId) async {
    return await _repository.getVocabsInRange(startId, endId);
  }

  // ----------------------------------------------------------------------
  // LEARNING LOGIC (New Words)
  // ----------------------------------------------------------------------

  /// Fetches words that have not been learned yet.
  /// Logic: Filters for entries where [isLearned] is false.
  Future<List<Vocab>> getWordsToLearn({int limit = 10}) async {
    final newWords = await _repository.getWhereLearned(false);

    return newWords.take(limit).toList();
  }

  // ----------------------------------------------------------------------
  // REVIEW LOGIC (Spaced Repetition)
  // ----------------------------------------------------------------------

  /// Finds vocabularies for review based on Spaced Repetition logic.
  /// Logic: Only includes words already marked as [isLearned].
  Future<List<Vocab>> findVocabsForReview({int limit = 10}) async {
    final learnedWords = await _repository.getWhereLearned(true);
    final now = DateTime.now();

    // 1. Filter: Must be learned and passed the 15-minute cooldown period
    final candidates = learnedWords.where((v) {
      final isCooldownOver = now.difference(v.lastReview).inMinutes >= 15;
      return isCooldownOver;
    }).toList();

    if (candidates.isEmpty) return [];

    // 2. Weight Calculation: Priority = TimeSinceLastReview / (Strength + 1)
    final scoredList = candidates.map((vocab) {
      final minsSinceReview = now.difference(vocab.lastReview).inMinutes;
      
      // Proficient words (high strength) get lower scores to appear less often
      double score = minsSinceReview / (vocab.strength + 1);

      // Apply small random noise to vary the order slightly
      return {
        'vocab': vocab, 
        'score': score + (_random.nextDouble() * 5.0)
      };
    }).toList();

    // 3. Sort by score DESC (Highest score = Most urgent)
    scoredList.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    return scoredList.take(limit).map((e) => e['vocab'] as Vocab).toList();
  }

  /// Updates vocabulary state after a user's answer.
  /// Automatically marks the word as [isLearned] upon the first review.
  Future<void> reviewVocab(Vocab vocab, bool isCorrect) async {
    // Update strength based on correctness
    Vocab updatedVocab = isCorrect 
        ? vocab.increaseStrength() 
        : vocab.decreaseStrength();

    // Transition from "New" to "Learned" status
    if (!updatedVocab.isLearned) {
      updatedVocab = updatedVocab.copyWith(isLearned: true);
    }

    // Persist changes to the data layer
    await _repository.saveVocab(updatedVocab);
  }

  /// Retrieves all vocabularies that have been marked as learned.
  Future<List<Vocab>> getLearnedVocabs() async {
    final learnedWords = await _repository.getWhereLearned(true);
    return learnedWords;
  }
}