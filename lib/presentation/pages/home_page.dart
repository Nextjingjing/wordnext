import 'package:flutter/material.dart';
import '../../domain/services/vocab_service.dart';
import '../../domain/entities/vocab.dart';
import 'learning_page.dart';
import 'dictionary_page.dart';

class HomePage extends StatefulWidget {
  final VocabService vocabService;

  const HomePage({super.key, required this.vocabService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _learnedCount = 0;
  int _newWordsAvailable = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  /// Refreshes the dashboard statistics
  Future<void> _refreshStats() async {
    setState(() => _isLoading = true);

    // In a real app, you might want to add a 'count' method to the repository
    // but for now, we fetch the lists to get the length.
    final allVocabs = await widget.vocabService.getVocabByRangeId(1, 4000);
    final learnable = await widget.vocabService.getWordsToLearn();

    if (mounted) {
      setState(() {
        _learnedCount = allVocabs.where((v) => v.isLearned).length;
        _newWordsAvailable = learnable.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDashboard(),
                  const SizedBox(height: 32),
                  Text(
                    "Learning Sessions",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSessionCard(
                    title: "Learn New Words",
                    subtitle: "Expand your vocabulary",
                    countText: "$_newWordsAvailable words waiting",
                    icon: Icons.auto_stories,
                    color: Colors.blueAccent,
                    onTap: () => _startSession(isReview: false),
                  ),
                  const SizedBox(height: 16),
                  _buildSessionCard(
                    title: "Review Session",
                    subtitle: "Spaced Repetition System",
                    countText: "Smart scheduling",
                    icon: Icons.psychology,
                    color: Colors.orangeAccent,
                    onTap: () => _startSession(isReview: true),
                  ),
                  const SizedBox(height: 16),
                  _buildSessionCard(
                    title: "Dictionary",
                    subtitle: "Browse all words and filters",
                    countText: "Search & explore",
                    icon: Icons.menu_book,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DictionaryPage(vocabService: widget.vocabService),
                      ),
                    ).then((_) => _refreshStats()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar.large(
      title: const Text("WordNext"),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshStats),
      ],
    );
  }

  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                "YOUR PROGRESS",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("Learned", "$_learnedCount"),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem(
                "Mastery",
                "${(_learnedCount / 38).toStringAsFixed(1)}%",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSessionCard({
    required String title,
    required String subtitle,
    required String countText,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(
                    countText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _startSession({required bool isReview}) async {
    List<Vocab> sessionWords;

    // 1. Fetch data based on the mode
    if (isReview) {
      sessionWords = await widget.vocabService.findVocabsForReview(limit: 10);
    } else {
      sessionWords = await widget.vocabService.getWordsToLearn(limit: 10);
    }

    // 2. Build-in safety check for asynchronous calls in Flutter
    if (!mounted) return;

    // 3. Handle Empty State
    if (sessionWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReview
                ? "No words to review right now! ☕"
                : "Amazing! You've learned all available words. 🎉",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 4. Navigate to the learning/review page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningPage(
          words: sessionWords,
          vocabService: widget.vocabService,
        ),
      ),
    );

    // 5. Refresh statistics automatically after returning to Home
    if (mounted) {
      _refreshStats();
    }
  }
}
