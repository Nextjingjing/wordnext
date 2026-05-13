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
  
  // Data list and loading state
  List<Vocab> _words = [];
  bool _isLoading = false;
  
  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 50;
  int _totalCount = 0;
  int _totalPages = 0;

  final Map<int, int> _pageLearnedCounts = {};

  @override
  void initState() {
    super.initState();
    _initialFetch();
  }

  Future<void> _initialFetch() async {
    setState(() => _isLoading = true);
    try {
      _totalCount = await widget.vocabService.getTotalCount(learnedStatus: null);
      
      _totalPages = (_totalCount / _itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;

      for (int page = 1; page <= _totalPages; page++) {
        int offset = (page - 1) * _itemsPerPage;
        // ดึงข้อมูลคำศัพท์ของหน้านั้นๆ มาเช็ก
        List<Vocab> pageWords = await widget.vocabService.getMany(
          limit: _itemsPerPage,
          offset: offset,
        );
        int learnedInPage = pageWords.where((v) => v.isLearned).length;
        _pageLearnedCounts[page] = learnedInPage;
      }

      await _fetchData();
    } catch (e) {
      debugPrint("Initial Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      int offset = (_currentPage - 1) * _itemsPerPage;
      
      List<Vocab> fetchedWords = await widget.vocabService.getMany(
        limit: _itemsPerPage,
        offset: offset,
      );

      _pageLearnedCounts[_currentPage] = fetchedWords.where((v) => v.isLearned).length;

      if (mounted) {
        setState(() {
          _words = fetchedWords;
          _isLoading = false;
        });
        _scrollToCurrentPageIndicator();
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changePage(int newPage) {
    if (newPage < 1 || newPage > _totalPages || _isLoading) return;
    setState(() => _currentPage = newPage);
    _fetchData();
  }

  void _scrollToCurrentPageIndicator() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageScrollController.hasClients) {
        double position = (_currentPage - 1) * 54.0;
        _pageScrollController.animateTo(
          position, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Dictionary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("$_totalCount words", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _words.isEmpty 
                ? const Center(child: Text("No data found"))
                : ListView.separated(
                    itemCount: _words.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => _buildVocabTile(_words[i]),
                  ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildVocabTile(Vocab v) {
    return ListTile(
      leading: Icon(
        v.isLearned ? Icons.check_circle : Icons.circle_outlined,
        color: v.isLearned ? Colors.green : Colors.grey.shade300,
      ),
      title: Text(v.word, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(v.translated),
      onTap: () => _showDetail(v),
    );
  }

  Widget _buildPaginationBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border(top: BorderSide(color: Colors.grey.shade200))
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left), 
            onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null
          ),
          Expanded(
            child: ListView.builder(
              controller: _pageScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _totalPages,
              itemBuilder: (ctx, i) {
                int p = i + 1;
                bool isActive = _currentPage == p;
                
                int learnedCount = _pageLearnedCounts[p] ?? 0;
                
                int totalInPage = (p == _totalPages) 
                    ? (_totalCount % _itemsPerPage == 0 ? _itemsPerPage : _totalCount % _itemsPerPage)
                    : _itemsPerPage;
                
                double progressPercent = totalInPage > 0 ? (learnedCount / totalInPage) : 0.0;

                return GestureDetector(
                  onTap: () => _changePage(p),
                  child: Container(
                    width: 46,
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive ? Colors.deepPurple.shade700 : Colors.grey.shade300,
                        width: isActive ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: progressPercent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            "$p",
                            style: TextStyle(
                              // ถ้าสีเขียวขึ้นมาเกินครึ่งหน้า ให้เปลี่ยนเลขเป็นสีขาวเพื่อให้ยังมองเห็นชัด
                              color: progressPercent > 0.5 ? Colors.white : Colors.black87,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: isActive ? 15 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right), 
            onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null
          ),
        ],
      ),
    );
  }

  /// Shows the vocabulary detail in a BottomSheet with full information
  void _showDetail(Vocab vocab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + 24, 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    vocab.word,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vocab.partOfSpeech.toLowerCase(),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              "ความหมาย: ${vocab.translated}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const Divider(height: 24, thickness: 1),

            if (vocab.definitionEn.isNotEmpty) ...[
              const Text("Definition:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                vocab.definitionEn,
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.3),
              ),
              const SizedBox(height: 16),
            ],

            if (vocab.exampleSentence.isNotEmpty) ...[
              const Text("Example Sentence:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  vocab.exampleSentence,
                  style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade800, height: 1.3),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, size: 20, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        "Strength: ${vocab.strength}",
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _tts.speak(vocab.word),
                icon: const Icon(Icons.volume_up, color: Colors.white),
                label: const Text("Pronounce", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}