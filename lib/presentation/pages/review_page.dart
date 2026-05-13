import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/vocab.dart';
import '../../domain/services/vocab_service.dart';

class ReviewPage extends StatefulWidget {
  final List<Vocab> words;
  final VocabService vocabService;

  const ReviewPage({
    super.key,
    required this.words,
    required this.vocabService,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

enum ReviewStep { spelling, meaning, summary }

class _ReviewPageState extends State<ReviewPage> {
  final FlutterTts _tts = FlutterTts();
  int _currentIndex = 0;

  ReviewStep _currentStep = ReviewStep.spelling;
  String _displayWord = "";
  List<String> _spellingOptions = [];
  List<String> _meaningOptions = [];
  bool _isWrong = false;

  List<int> _blankIndices = [];
  Map<int, String> _userInputs = {};

  @override
  void initState() {
    super.initState();
    if (widget.words.isNotEmpty) {
      _setupCurrentWord();
    }
  }

  void _setupCurrentWord() {
    final vocab = widget.words[_currentIndex];
    _userInputs.clear();
    _blankIndices.clear();
    _generateSpellingGame(vocab.word.toUpperCase());
    _generateMeaningOptions(vocab);
    _playCurrentWord();
  }

  void _generateSpellingGame(String word) {
    Random random = Random();
    List<String> chars = word.split('');

    List<int> validLetterIndices = [];
    for (int i = 0; i < word.length; i++) {
      if (word[i] != ' ') {
        validLetterIndices.add(i);
      }
    }

    int missingCount = (validLetterIndices.length * 0.4).ceil();
    if (missingCount == 0 && validLetterIndices.isNotEmpty) missingCount = 1;

    Set<int> missingIndices = {};
    while (missingIndices.length < missingCount &&
        validLetterIndices.isNotEmpty) {
      int randomIndex =
          validLetterIndices[random.nextInt(validLetterIndices.length)];
      missingIndices.add(randomIndex);
    }

    _blankIndices = missingIndices.toList()..sort();

    for (var index in _blankIndices) {
      chars[index] = "_";
    }

    List<String> correctChars = word
        .toUpperCase()
        .replaceAll(' ', '')
        .split('')
        .toSet()
        .toList();
    List<String> alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('');
    alphabet.removeWhere((char) => correctChars.contains(char));
    alphabet.shuffle();

    setState(() {
      _displayWord = chars.join(' ');
      _spellingOptions = [...correctChars, ...alphabet.take(4)]..shuffle();
    });
  }

  void _generateMeaningOptions(Vocab currentVocab) {
    List<String> distractors = widget.words
        .where((v) => v.word != currentVocab.word)
        .map((v) => v.translated)
        .toList();
    distractors.shuffle();

    setState(() {
      _meaningOptions = [currentVocab.translated, ...distractors.take(3)]
        ..shuffle();
    });
  }

  void _playCurrentWord() async {
    await _tts.setLanguage("en-US");
    await _tts.speak(widget.words[_currentIndex].word);
  }

  void _handleSpellingInput(String char) {
    int? nextBlank;
    for (int index in _blankIndices) {
      if (!_userInputs.containsKey(index)) {
        nextBlank = index;
        break;
      }
    }

    if (nextBlank != null) {
      setState(() {
        _userInputs[nextBlank!] = char;
        _updateDisplayString();
      });
    }
  }

  void _updateDisplayString() {
    final originalWord = widget.words[_currentIndex].word.toUpperCase();
    List<String> chars = originalWord.split('');

    for (int index in _blankIndices) {
      chars[index] = _userInputs[index] ?? "_";
    }
    _displayWord = chars.join(' ');
  }

  void _undoSpelling() {
    if (_userInputs.isEmpty) return;

    setState(() {
      int lastFilledIndex = _blankIndices.lastWhere(
        (idx) => _userInputs.containsKey(idx),
      );
      _userInputs.remove(lastFilledIndex);
      _updateDisplayString();
    });
  }

  void _submitSpelling() {
    final originalWord = widget.words[_currentIndex].word.toUpperCase().replaceAll(' ', '');
    final currentFullWord = _displayWord.replaceAll(' ', '');

    if (currentFullWord == originalWord) {
      setState(() {
        _currentStep = ReviewStep.meaning;
      });
    } else {
      _handleFailure();
    }
  }

  void _handleMeaning(String selected) {
    if (selected == widget.words[_currentIndex].translated) {
      _handleSuccess();
    } else {
      _handleFailure();
    }
  }

  void _handleSuccess() async {
    await widget.vocabService.reviewVocab(widget.words[_currentIndex], true);
    _moveToNext();
  }

  void _handleFailure() async {
    await widget.vocabService.reviewVocab(widget.words[_currentIndex], false);
    setState(() {
      _isWrong = true;
      _currentStep = ReviewStep.summary;
    });
  }

  void _moveToNext() {
    if (_currentIndex < widget.words.length - 1) {
      setState(() {
        _currentIndex++;
        _isWrong = false;
        _currentStep = ReviewStep.spelling;
        _displayWord = "";
      });
      _setupCurrentWord();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty)
      return const Scaffold(body: Center(child: Text("No words")));

    if (_displayWord.isEmpty && _currentStep == ReviewStep.spelling) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Review (${_currentIndex + 1}/${widget.words.length})"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.words.length,
            ),
            const SizedBox(height: 40),
            IconButton(
              iconSize: 72,
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.deepPurple,
              ),
              onPressed: _playCurrentWord,
            ),
            const SizedBox(height: 40),
            Expanded(child: _buildGameContent(widget.words[_currentIndex])),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent(Vocab vocab) {
    switch (_currentStep) {
      case ReviewStep.spelling:
        bool isFull = _userInputs.length == _blankIndices.length;
        return Column(
          children: [
            Text(
              _displayWord,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ..._spellingOptions.map((char) => _letterButton(char)).toList(),

                // ปุ่มลบ
                _actionButton(
                  icon: Icons.backspace_outlined,
                  color: Colors.orange,
                  onTap: _userInputs.isNotEmpty ? _undoSpelling : null,
                ),

                // ปุ่มส่งคำตอบ (Submit)
                _actionButton(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onTap: isFull ? _submitSpelling : null,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        );
      // Stage อื่นๆ (meaning, summary) เหมือนเดิม...
      case ReviewStep.meaning:
        return Column(
          children: [
            Text(
              vocab.word.toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Spacer(),
            ..._meaningOptions.map((m) => _meaningButton(m)).toList(),
            const SizedBox(height: 40),
          ],
        );
      case ReviewStep.summary:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            Text(
              vocab.word.toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              vocab.translated,
              style: const TextStyle(fontSize: 24, color: Colors.blueGrey),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _moveToNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text(
                "NEXT WORD",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
    }
  }

  Widget _letterButton(String char) {
    return ElevatedButton(
      onPressed: () => _handleSpellingInput(char),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(55, 55),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Colors.deepPurple),
      ),
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? color : Colors.grey.shade300,
          ),
        ),
        child: Icon(icon, color: onTap != null ? color : Colors.grey),
      ),
    );
  }

  Widget _meaningButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _handleMeaning(text),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          side: const BorderSide(color: Colors.black12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.black87),
        ),
      ),
    );
  }
}
