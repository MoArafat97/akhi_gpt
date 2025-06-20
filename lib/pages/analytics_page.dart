import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../services/hive_service.dart';
import '../models/mood_entry.dart';

class AnalyticsPage extends StatefulWidget {
  final Color bgColor;

  const AnalyticsPage({super.key, this.bgColor = const Color(0xFFC76C5A)});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HiveService _hiveService = HiveService.instance;
  final ValueNotifier<List<MoodEntry>> _moodEntriesNotifier = ValueNotifier([]);
  final TextEditingController _moodController = TextEditingController();

  List<Map<String, dynamic>> _duaDatabase = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDuaDatabase();
    _loadMoodEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _moodController.dispose();
    _moodEntriesNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadDuaDatabase() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context).loadString('assets/mood_dua.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      _duaDatabase = jsonData.cast<Map<String, dynamic>>();
      developer.log('Loaded ${_duaDatabase.length} duʿāʾ entries', name: 'AnalyticsPage');
    } catch (e) {
      developer.log('Error loading duʿāʾ database: $e', name: 'AnalyticsPage');
    }
  }

  Future<void> _loadMoodEntries() async {
    try {
      setState(() => _isLoading = true);
      final entries = await _hiveService.getMoodEntries();
      _moodEntriesNotifier.value = entries;
      developer.log('Loaded ${entries.length} mood entries', name: 'AnalyticsPage');
    } catch (e) {
      developer.log('Error loading mood entries: $e', name: 'AnalyticsPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading mood entries: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getSuggestions(String query) {
    if (query.isEmpty) return [];

    final suggestions = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    for (final dua in _duaDatabase) {
      final keywords = List<String>.from(dua['keywords'] ?? []);
      final mood = dua['mood']?.toString().toLowerCase() ?? '';

      // Check if query matches mood or any keyword
      if (mood.contains(queryLower) || keywords.any((keyword) => keyword.toLowerCase().contains(queryLower))) {
        suggestions.add(dua);
      }
    }

    return suggestions.take(5).toList(); // Limit to 5 suggestions
  }

  Future<void> _saveMoodEntry(Map<String, dynamic> duaData) async {
    try {
      final entry = MoodEntry(
        mood: duaData['mood'] ?? '',
        duaArabic: duaData['duaArabic'] ?? '',
        translit: duaData['translit'] ?? '',
        english: duaData['english'] ?? '',
      );

      await _hiveService.addMoodEntry(entry);
      developer.log('Added mood entry: ${entry.mood}', name: 'AnalyticsPage');

      // Clear the text field
      _moodController.clear();

      // Reload entries
      await _loadMoodEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duʿāʾ saved for ${entry.mood} mood!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error saving mood entry: $e', name: 'AnalyticsPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving duʿāʾ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: widget.bgColor,
        appBar: AppBar(
          backgroundColor: widget.bgColor.withValues(alpha: 0.9),
          title: Text(
            'Analytics',
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Mood Duʿāʾ'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMoodDuaTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 80,
            color: widget.bgColor.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 24),
          Text(
            'Analytics Overview',
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: GoogleFonts.lexend(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDuaTab() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Duʿāʾ Autocomplete',
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type your mood to find Islamic duʿāʾ (prayers) for guidance',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),

          // Typeahead search field
          TypeAheadField<Map<String, dynamic>>(
            controller: _moodController,
            suggestionsCallback: _getSuggestions,
            itemBuilder: (context, suggestion) {
              return ListTile(
                leading: Text(
                  _getMoodEmoji(suggestion['mood'] ?? ''),
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(
                  suggestion['mood'] ?? '',
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  suggestion['english'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
            onSelected: _saveMoodEntry,
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'How are you feeling? (e.g., anxious, grateful, sad)',
                  hintStyle: GoogleFonts.inter(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Saved mood entries
          Expanded(
            child: ValueListenableBuilder<List<MoodEntry>>(
              valueListenable: _moodEntriesNotifier,
              builder: (context, entries, child) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved duʿāʾ yet',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for your mood above to save Islamic prayers',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildMoodEntryCard(entry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEntryCard(MoodEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Dismissible(
        key: Key(entry.key.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) async {
          try {
            await _hiveService.deleteMoodEntryObject(entry);
            await _loadMoodEntries();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Duʿāʾ deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            developer.log('Error deleting mood entry: $e', name: 'AnalyticsPage');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.moodEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.mood.toUpperCase(),
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    entry.timeString,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Arabic text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.duaArabic,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),

              const SizedBox(height: 8),

              // Transliteration
              Text(
                entry.translit,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 8),

              // English translation
              Text(
                entry.english,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'anxious':
      case 'worried':
      case 'stress':
        return '😰';
      case 'sad':
      case 'depressed':
      case 'grief':
        return '😢';
      case 'grateful':
      case 'thankful':
      case 'blessed':
        return '🙏';
      case 'seeking guidance':
      case 'confused':
      case 'lost':
        return '🤲';
      case 'angry':
      case 'frustrated':
        return '😠';
      case 'seeking forgiveness':
      case 'repentance':
        return '💔';
      case 'seeking peace':
      case 'calm':
        return '☮️';
      case 'seeking strength':
      case 'weak':
      case 'tired':
        return '💪';
      case 'seeking protection':
      case 'scared':
        return '🛡️';
      case 'seeking success':
      case 'ambitious':
        return '🌟';
      case 'lonely':
      case 'isolated':
        return '😔';
      case 'hopeful':
      case 'optimistic':
        return '🌈';
      default:
        return '🤲';
    }
  }
}
