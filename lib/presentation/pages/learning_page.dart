import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import '../../domain/entities/vocab.dart';
import '../../domain/services/vocab_service.dart';
import '../../infrastructure/tts/tts_config.dart';

class LearningPage extends StatefulWidget {
  final List<Vocab> words;
  final VocabService vocabService;

  const LearningPage({
    super.key,
    required this.words,
    required this.vocabService,
  });

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _spellingController = TextEditingController();

  int _currentIndex = 0;
  bool _isFlipped = false; // Controls the Flashcard flip state
  bool _isTesting = false; // Switches between Study mode and Quiz mode
  bool _hasSpelledCorrectly = false;
  bool _hasChosenCorrectMeaning = false;
  List<String> _choices = [];
  List<String> _scrambledLetters = [];
  List<String> _userSelectedLetters = [];

  @override
  void initState() {
    super.initState();
    configureTtsForPlatform(_tts);
    _prepareWordSession();
  }

  @override
  void dispose() {
    _tts.stop();
    _spellingController.dispose();
    super.dispose();
  }

  /// Reset all states and prepare for a new word
  void _prepareWordSession() {
    setState(() {
      _isFlipped = false;
      _isTesting = false;
      _hasSpelledCorrectly = false;
      _hasChosenCorrectMeaning = false;
      _spellingController.clear();
      // Prepare scrambled letters for the spelling challenge
      _userSelectedLetters = [];

      // Ensure we have a valid word before scrambling
      String word = widget.words[_currentIndex].word.toUpperCase();
      _scrambledLetters = word.split('')..shuffle();
    });
    _generateChoices();
    _playVoice(widget.words[_currentIndex].word);
  }

  /// Text-to-Speech: Plays the English pronunciation
  Future<void> _playVoice(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  /// Generates 1 correct answer and 3 random distractors
  void _generateChoices() {
    final current = widget.words[_currentIndex];
    List<String> options = [current.translated];

    List<String> distractors = widget.words
        .where((v) => v.translated != current.translated)
        .map((v) => v.translated)
        .toList();

    distractors.shuffle();
    options.addAll(distractors.take(3));

    while (options.length < 4) {
      options.add("Translation ${options.length + 1}");
    }

    options.shuffle();
    setState(() => _choices = options);
  }

  /// Failure Handler: Resets the user back to the Study phase
  void _handleFailure(String message) {
    HapticFeedback.vibrate(); // Vibrate on error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 1),
      ),
    );
    _prepareWordSession(); // Kick back to start of the current word
  }

  /// Logic for moving to the next word after passing all tests
  void _handleNextWord() async {
    await widget.vocabService.reviewVocab(widget.words[_currentIndex], true);

    if (_currentIndex < widget.words.length - 1) {
      setState(() {
        _currentIndex++;
        _prepareWordSession();
      });
    } else {
      _showFinishDialog();
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session Complete!"),
        content: const Text("You've mastered this set of words."),
        actions: [
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Back to Home"),
          ),
        ],
      ),
    );
  }

  void _onLetterTap(int index) {
    setState(() {
      _userSelectedLetters.add(_scrambledLetters.removeAt(index));
      _checkSpelling();
    });
  }

  void _undoLetter() {
    if (_userSelectedLetters.isNotEmpty) {
      setState(() {
        _scrambledLetters.add(_userSelectedLetters.removeLast());
        _scrambledLetters.shuffle();
      });
    }
  }

  void _clearLetters() {
    _prepareWordSession();
  }

  void _checkSpelling() {
    String currentWord = widget.words[_currentIndex].word.toUpperCase();
    String userWord = _userSelectedLetters.join();

    if (userWord == currentWord) {
      setState(() => _hasSpelledCorrectly = true);
      HapticFeedback.mediumImpact();
      _playSystemSound("Nice!");
    } else if (userWord.length == currentWord.length) {
      _handleFailure("Spelling is incorrect!");
      HapticFeedback.vibrate();
    }
  }

  Future<void> _playSystemSound(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.8);
    await _tts.setPitch(1.2);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final vocab = widget.words[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Word ${_currentIndex + 1}/${widget.words.length}"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- 1. Audio Control (External) ---
            IconButton.filledTonal(
              iconSize: 48,
              icon: const Icon(Icons.volume_up_rounded),
              onPressed: () => _playVoice(vocab.word),
            ),
            const SizedBox(height: 24),

            if (!_isTesting) ...[
              // --- 2. Phase 1: Study Mode (Flip Card) ---
              const Text(
                "Tap the card to see translation",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isFlipped = !_isFlipped);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: _buildFlipTransition,
                  child: _isFlipped ? _buildBack(vocab) : _buildFront(vocab),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => setState(() => _isTesting = true),
                icon: const Icon(Icons.psychology),
                label: const Text(
                  "Got it! Start Quiz",
                  style: TextStyle(fontSize: 18),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                ),
              ),
            ] else ...[
              // --- 3. Phase 2: Quiz Mode (Spelling & Choices) ---
              if (!_hasSpelledCorrectly) ...[
                const Text(
                  "Step 1: Spelling Challenge",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.deepPurple.shade100,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _userSelectedLetters.join(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _scrambledLetters.asMap().entries.map((entry) {
                    return ActionChip(
                      label: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _onLetterTap(entry.key),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.deepPurple),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _undoLetter,
                      icon: const Icon(Icons.undo, color: Colors.orange),
                      label: const Text(
                        "Undo",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearLetters,
                      icon: const Icon(Icons.refresh, color: Colors.red),
                      label: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              // step 2: multiple choice only shows after spelling is correct
              ] else if (!_hasChosenCorrectMeaning) ...[
                const Text(
                  "Step 2: Multiple Choice",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  vocab.word.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 24),
                ..._choices.map(
                  (choice) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () {
                          if (choice == vocab.translated) {
                            setState(() => _hasChosenCorrectMeaning = true);
                            _playSystemSound("Excellent!");
                          } else {
                            _handleFailure("Wrong Meaning! Start over.");
                          }
                        },
                        child: Text(
                          choice,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text(
                  "Correct!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _handleNextWord,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Next Word"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // --- UI Components: Flashcard Front ---
  Widget _buildFront(Vocab vocab) {
    return Container(
      key: const ValueKey(false),
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              vocab.word,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
          const Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                Icon(Icons.flip, color: Colors.deepPurple),
                Text("FLIP", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components: Flashcard Back ---
  Widget _buildBack(Vocab vocab) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: Container(
        key: const ValueKey(true),
        height: 300,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.deepPurple.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vocab.translated,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              vocab.partOfSpeech,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const Divider(height: 30),
            Text(
              vocab.definitionEn,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              "\"${vocab.exampleSentence}\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Animation Helper ---
  Widget _buildFlipTransition(Widget widget, Animation<double> animation) {
    final rotate = Tween(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotate,
      builder: (context, child) {
        final isFront = ValueKey(_isFlipped) == widget.key;
        final tilt = isFront ? rotate.value : rotate.value - pi;
        return Transform(
          transform: Matrix4.rotationY(tilt),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget,
    );
  }
}
