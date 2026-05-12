import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/vocab.dart';
import '../../domain/services/vocab_service.dart';

class DictionaryPage extends StatefulWidget {
  final VocabService vocabService;
  const DictionaryPage({super.key, required this.vocabService});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final FlutterTts _tts = FlutterTts();
  final ScrollController _pageScrollController = ScrollController();
  
  // Data State
  List<Vocab> _words = [];
  bool _isLoading = false;
  
  // Dynamic Pagination State
  int _currentPage = 1;
  final int _itemsPerPage = 50;
  int _totalCount = 0;
  int _totalPages = 0;

  // Filter State: null = All, 1 = Learned, 0 = Not Learned
  int? _filterLearned; 
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _refreshData(resetPage: true);
  }

  /// Fetches the dynamic count and the specific page data from the DB
  Future<void> _refreshData({bool resetPage = false}) async {
    if (resetPage) _currentPage = 1;
    
    setState(() => _isLoading = true);

    try {
      // 1. Get the actual total count based on current filter from Database
      final int count = await widget.vocabService.getTotalCount(
        learnedStatus: _filterLearned
      );
      
      // 2. Calculate total pages (e.g., 50 words / 100 per page = 1 page)
      int calculatedPages = (count / _itemsPerPage).ceil();
      if (calculatedPages == 0) calculatedPages = 1;

      // 3. Calculate offset for SQL: (Page - 1) * Limit
      int offset = (_currentPage - 1) * _itemsPerPage;
      
      List<Vocab> fetchedWords;
      if (_filterLearned == null) {
        // Fetch All
        fetchedWords = await widget.vocabService.getMany(limit: _itemsPerPage, offset: offset);
      } else {
        // Fetch Filtered (Learned or Unlearned)
        fetchedWords = await widget.vocabService.getWhereLearned(
          isLearned: _filterLearned == 1,
          limit: _itemsPerPage,
          offset: offset,
          newestFirst: _newestFirst,
        );
      }

      if (mounted) {
        setState(() {
          _totalCount = count;
          _totalPages = calculatedPages;
          _words = fetchedWords;
          _isLoading = false;
        });
        _scrollToCurrentPageIndicator();
      }
    } catch (e) {
      debugPrint("Dictionary Error: $e");
      setState(() => _isLoading = false);
    }
  }

  /// Handles page selection and data reloading
  void _changePage(int newPage) {
    if (newPage < 1 || newPage > _totalPages) return;
    setState(() => _currentPage = newPage);
    _refreshData();
  }

  /// Automatically scrolls the horizontal page bar to keep current page visible
  void _scrollToCurrentPageIndicator() {
    if (_pageScrollController.hasClients) {
      double position = (_currentPage - 1) * 54.0; // Width + Margin
      _pageScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Dictionary", style: TextStyle(fontSize: 18)),
            Text("$_totalCount words found", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              setState(() {
                if (val == 21) { _filterLearned = 1; _newestFirst = true; }
                else if (val == 22) { _filterLearned = 1; _newestFirst = false; }
                else { _filterLearned = val; }
              });
              _refreshData(resetPage: true);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: null, child: Text("Show All Words")),
              const PopupMenuItem(value: 21, child: Text("Learned (Newest First)")),
              const PopupMenuItem(value: 22, child: Text("Learned (Oldest First)")),
              const PopupMenuItem(value: 0, child: Text("Not Learned Yet")),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Vocabulary List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _words.isEmpty 
                ? const Center(child: Text("No words found here."))
                : ListView.separated(
                    itemCount: _words.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final v = _words[i];
                      return ListTile(
                        leading: Icon(
                          v.isLearned ? Icons.check_circle : Icons.circle_outlined,
                          color: v.isLearned ? Colors.green : Colors.grey.shade300,
                        ),
                        title: Text(v.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(v.translated),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                        onTap: () => _showDetail(v),
                      );
                    },
                  ),
          ),
          
          // Horizontal Page Selector
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    // Hide if everything fits on one page
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
          ),
          Expanded(
            child: ListView.builder(
              controller: _pageScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _totalPages,
              itemBuilder: (ctx, i) {
                int p = i + 1;
                bool active = _currentPage == p;
                return GestureDetector(
                  onTap: () => _changePage(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? Colors.deepPurple : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? Colors.deepPurple : Colors.grey.shade300),
                    ),
                    child: Text(
                      "$p",
                      style: TextStyle(
                        color: active ? Colors.white : Colors.black87,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  void _showDetail(Vocab vocab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(vocab.word, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 32, color: Colors.deepPurple),
                  onPressed: () => _tts.speak(vocab.word),
                ),
              ],
            ),
            Text(vocab.partOfSpeech.toUpperCase(), style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const Divider(height: 40),
            _detailItem("Translation", vocab.translated),
            _detailItem("Definition (EN)", vocab.definitionEn),
            _detailItem("Example Sentence", vocab.exampleSentence),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? "No data available" : value, style: const TextStyle(fontSize: 18, height: 1.4)),
        ],
      ),
    );
  }
}