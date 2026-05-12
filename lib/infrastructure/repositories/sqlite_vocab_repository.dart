import '../../domain/entities/vocab.dart';
import '../../domain/repositories/vocab_repository.dart';
import '../database/database_helper.dart';

/// Implementation of the [VocabRepository] using SQLite as the data source.
class SqliteVocabRepository implements VocabRepository {
  final dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Vocab>> getAllVocabs() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('vocabs');

    // Convert the List<Map> into a List<Vocab>
    return List.generate(maps.length, (i) {
      return Vocab(
        id: maps[i]['id'],
        word: maps[i]['word'],
        translated: maps[i]['translated'],
        partOfSpeech: maps[i]['part_of_speech'] ?? '',
        definitionEn: maps[i]['definition_en'] ?? '',
        exampleSentence: maps[i]['example_sentence'] ?? '',
        strength: maps[i]['strength'] ?? 0,
        lastReview: DateTime.parse(maps[i]['last_review']),
        isLearned: maps[i]['is_learned'] == 1,
      );
    });
  }

  @override
  Future<void> saveVocab(Vocab vocab) async {
    final db = await dbHelper.database;
    
    // Perform an update since the database is pre-populated
    await db.update(
      'vocabs',
      {
        'translated': vocab.translated,
        'strength': vocab.strength,
        'last_review': vocab.lastReview.toIso8601String(),
        'is_learned': vocab.isLearned ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [vocab.id],
    );
  }

  @override
  Future<Vocab?> findByWord(String word) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabs',
      where: 'word = ?',
      whereArgs: [word],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    
    return Vocab(
      id: maps[0]['id'],
      word: maps[0]['word'],
      translated: maps[0]['translated'],
      partOfSpeech: maps[0]['part_of_speech'] ?? '',
      definitionEn: maps[0]['definition_en'] ?? '',
      exampleSentence: maps[0]['example_sentence'] ?? '',
      strength: maps[0]['strength'] ?? 0,
      lastReview: DateTime.parse(maps[0]['last_review']),
      isLearned: maps[0]['is_learned'] == 1,
    );
  }

  @override
  Future<void> deleteVocab(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'vocabs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Vocab?> getById(int id) async {
    final db = await dbHelper.database;
    
    // Query the table for a specific ID
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    // Return null if no record is found
    if (maps.isEmpty) return null;

    // Convert the first result map into a Vocab object
    return Vocab(
      id: maps[0]['id'],
      word: maps[0]['word'],
      translated: maps[0]['translated'],
      partOfSpeech: maps[0]['part_of_speech'] ?? '',
      definitionEn: maps[0]['definition_en'] ?? '',
      exampleSentence: maps[0]['example_sentence'] ?? '',
      strength: maps[0]['strength'] ?? 0,
      lastReview: DateTime.parse(maps[0]['last_review']),
      isLearned: maps[0]['is_learned'] == 1,
    );
  }

  @override
  Future<List<Vocab>> getVocabsInRange(int startId, int endId) async {
    final db = await dbHelper.database;

    // Use BETWEEN for an inclusive range [startId, endId]
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabs',
      where: 'id BETWEEN ? AND ?',
      whereArgs: [startId, endId],
      orderBy: 'id ASC',
    );

    return maps.map((map) => Vocab(
      id: map['id'],
      word: map['word'],
      translated: map['translated'],
      partOfSpeech: map['part_of_speech'] ?? '',
      definitionEn: map['definition_en'] ?? '',
      exampleSentence: map['example_sentence'] ?? '',
      strength: map['strength'] ?? 0,
      lastReview: DateTime.parse(map['last_review']),
      isLearned: map['is_learned'] == 1,
    )).toList();
  }
  
  @override
  Future<List<Vocab>> getWhereLearned(bool isLearned) async {
    final db = await dbHelper.database; // เปลี่ยนจาก database เป็น dbHelper.database

    final int learnedValue = isLearned ? 1 : 0;

    final List<Map<String, dynamic>> maps = await db.query(
      'vocabs',
      where: 'is_learned = ?',
      whereArgs: [learnedValue],
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      return Vocab(
        id: maps[i]['id'],
        word: maps[i]['word'],
        translated: maps[i]['translated'],
        partOfSpeech: maps[i]['part_of_speech'] ?? '',
        definitionEn: maps[i]['definition_en'] ?? '',
        exampleSentence: maps[i]['example_sentence'] ?? '',
        strength: maps[i]['strength'] ?? 0,
        lastReview: DateTime.parse(maps[i]['last_review']),
        isLearned: maps[i]['is_learned'] == 1,
      );
    });
  }
}