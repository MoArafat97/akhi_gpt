import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:ui';
import '../models/journal_entry.dart';
import '../models/anonymous_letter.dart';
import '../services/hive_service.dart';
import 'new_note_page.dart';
import 'edit_note_page.dart';
import 'letter_page.dart';

class JournalPage extends StatefulWidget {
  final Color bgColor;

  const JournalPage({super.key, this.bgColor = const Color(0xFFA8B97F)});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HiveService _hiveService = HiveService.instance;
  final ValueNotifier<List<JournalEntry>> _entriesNotifier = ValueNotifier([]);
  final ValueNotifier<List<AnonymousLetter>> _lettersNotifier = ValueNotifier([]);
  final TextEditingController _letterController = TextEditingController();
  bool _isLoading = false;
  Timer? _countdownTimer;
  final Set<dynamic> _revealedLetters = <dynamic>{}; // Track which letters are revealed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FloatingActionButton visibility
    });
    _loadEntries();
    _loadLetters();
    _startCountdownTimer();
  }



  @override
  void dispose() {
    _tabController.dispose();
    _letterController.dispose();
    _entriesNotifier.dispose();
    _lettersNotifier.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    try {
      setState(() => _isLoading = true);
      final entries = await _hiveService.getAllEntries();
      _entriesNotifier.value = entries;
      developer.log('Loaded ${entries.length} journal entries', name: 'JournalPage');
    } catch (e) {
      developer.log('Error loading entries: $e', name: 'JournalPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading entries: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    try {
      final deleted = await _hiveService.deleteEntryObject(entry);
      if (deleted) {
        developer.log('Deleted journal entry: ${entry.title}', name: 'JournalPage');
        await _loadEntries();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error deleting entry: $e', name: 'JournalPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLetters() async {
    try {
      setState(() => _isLoading = true);
      final letters = await _hiveService.getActiveLetters();
      _lettersNotifier.value = letters;
      developer.log('Loaded ${letters.length} active letters', name: 'JournalPage');
    } catch (e) {
      developer.log('Error loading letters: $e', name: 'JournalPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading letters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLetter() async {
    if (_letterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final letter = AnonymousLetter(
        text: _letterController.text.trim(),
      );

      await _hiveService.addLetter(letter);
      developer.log('Added new anonymous letter', name: 'JournalPage');

      // Clear form
      _letterController.clear();

      // Reload letters
      await _loadLetters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anonymous letter saved! It will auto-delete in 24 hours.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error saving letter: $e', name: 'JournalPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving letter: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Refresh letters to update countdown and remove expired ones
      _loadLetters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: widget.bgColor,
        appBar: AppBar(
          backgroundColor: widget.bgColor.withValues(alpha: 0.9),
          elevation: 0,
          title: Text(
            'Journal',
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _loadEntries();
                _loadLetters();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Journal'),
              Tab(text: 'Anonymous Box'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildJournalTab(),
            _buildAnonymousLetterTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_tabController.index == 0) {
              // Journal tab - create new journal entry
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NewNotePage(),
                ),
              );

              // Refresh data if a new entry was added
              if (result == true && mounted) {
                await _loadEntries();
              }
            } else {
              // Anonymous Letter tab - create new letter
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LetterPage(bgColor: widget.bgColor),
                ),
              );

              // Reload letters if a message was saved
              if (result == true && mounted) {
                await _loadLetters();
              }
            }
          },
          backgroundColor: Colors.white,
          foregroundColor: widget.bgColor,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildJournalTab() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
        : ValueListenableBuilder<List<JournalEntry>>(
            valueListenable: _entriesNotifier,
            builder: (context, entries, child) {
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No journal entries yet',
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap the + button to create your first entry',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Dismissible(
                    key: Key(entry.key.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Delete Entry',
                            style: GoogleFonts.lexend(
                              color: const Color(0xFF4F372D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete "${entry.title}"?',
                            style: GoogleFonts.inter(color: const Color(0xFF4F372D)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(color: Colors.grey[600]),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) => _deleteEntry(entry),
                    child: _buildEntryCard(entry),
                  );
                },
              );
            },
          );
  }

  Widget _buildAnonymousLetterTab() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Text(
            'Anonymous Letter Box',
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write anonymous letters that auto-delete in 24 hours',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),

          // Active letters section
          Text(
            'Active Messages',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ValueListenableBuilder<List<AnonymousLetter>>(
              valueListenable: _lettersNotifier,
              builder: (context, letters, child) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (letters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active messages',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Write your first anonymous message above',
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
                  itemCount: letters.length,
                  itemBuilder: (context, index) {
                    final letter = letters[index];
                    return _buildLetterCard(letter);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return GestureDetector(
      onTap: () async {
        // Navigate to edit page
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditNotePage(entry: entry),
          ),
        );

        // Refresh entries if changes were made
        if (result == true && mounted) {
          await _loadEntries();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4F372D),
                    ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF4F372D).withValues(alpha: 0.8),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  entry.formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  entry.timeString,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterCard(AnonymousLetter letter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Dismissible(
        key: Key(letter.key.toString()),
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
            await _hiveService.deleteLetterObject(letter);
            await _loadLetters();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Letter deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            developer.log('Error deleting letter: $e', name: 'JournalPage');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mail,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anonymous Letter',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: letter.timeUntilDeletion.inHours < 2
                          ? Colors.red.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      letter.remainingTimeString,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Letter content (blurred for privacy)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_revealedLetters.contains(letter.key)) {
                      _revealedLetters.remove(letter.key);
                    } else {
                      _revealedLetters.add(letter.key);
                    }
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // The actual text content
                        Text(
                          letter.text,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        // Blur overlay for privacy (only show if not revealed)
                        if (!_revealedLetters.contains(letter.key))
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.visibility_off,
                                        size: 16,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tap to reveal',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Show "Tap to hide" when revealed
                        if (_revealedLetters.contains(letter.key))
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Tap to hide',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Date and time
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${letter.formattedDate} at ${letter.timeString}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
