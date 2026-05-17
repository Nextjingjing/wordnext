import 'package:flutter/material.dart';
import 'infrastructure/repositories/sqlite_vocab_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'domain/services/vocab_service.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized before database setup
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // 1. Initialize Infrastructure (Data Layer)
  final vocabRepository = SqliteVocabRepository();

  // 2. Initialize Application Service (Logic Layer)
  final vocabService = VocabService(vocabRepository);

  runApp(MainApp(vocabService: vocabService));
}

class MainApp extends StatelessWidget {
  final VocabService vocabService;

  const MainApp({super.key, required this.vocabService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WordNext',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      // Pass the service down to the HomePage
      home: HomePage(vocabService: vocabService),
    );
  }
}