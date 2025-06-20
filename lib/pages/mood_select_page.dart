import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../services/hive_service.dart';

class MoodSelectPage extends StatefulWidget {
  final int entryKey;

  const MoodSelectPage({super.key, required this.entryKey});

  @override
  State<MoodSelectPage> createState() => _MoodSelectPageState();
}

class _MoodSelectPageState extends State<MoodSelectPage> {
  final HiveService _hiveService = HiveService.instance;
  bool _isUpdating = false;

  // Mood options with emojis
  final List<Map<String, String>> _moodOptions = [
    {'emoji': '😊', 'name': 'Happy', 'description': 'Feeling joyful and content'},
    {'emoji': '😌', 'name': 'Calm', 'description': 'Peaceful and relaxed'},
    {'emoji': '😔', 'name': 'Sad', 'description': 'Feeling down or melancholy'},
    {'emoji': '😠', 'name': 'Angry', 'description': 'Frustrated or upset'},
    {'emoji': '😰', 'name': 'Anxious', 'description': 'Worried or nervous'},
    {'emoji': '🤩', 'name': 'Excited', 'description': 'Enthusiastic and energetic'},
    {'emoji': '🙏', 'name': 'Grateful', 'description': 'Thankful and appreciative'},
    {'emoji': '🌟', 'name': 'Hopeful', 'description': 'Optimistic about the future'},
    {'emoji': '☮️', 'name': 'Peaceful', 'description': 'Serene and tranquil'},
    {'emoji': '😕', 'name': 'Confused', 'description': 'Uncertain or puzzled'},
    {'emoji': '😴', 'name': 'Tired', 'description': 'Exhausted or sleepy'},
    {'emoji': '🤔', 'name': 'Thoughtful', 'description': 'Reflective and contemplative'},
  ];

  Future<void> _selectMood(String moodName) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      // Get the journal entry from Hive
      final entry = _hiveService.journalBox.get(widget.entryKey);

      if (entry != null) {
        // Update the mood tag
        final updatedEntry = entry.copyWith(moodTag: moodName);

        // Save back to Hive using the key
        await _hiveService.journalBox.put(widget.entryKey, updatedEntry);

        developer.log('Updated entry ${widget.entryKey} with mood: $moodName', name: 'MoodSelectPage');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Journal entry saved with $moodName mood!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back to journal page with result
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Journal entry not found');
      }
    } catch (e) {
      developer.log('Error updating mood: $e', name: 'MoodSelectPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving mood: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _skipMoodSelection() async {
    if (_isUpdating) return;

    if (mounted) {
      // Show message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry saved without mood!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to journal page with result
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7), // Cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4F372D)),
          onPressed: _skipMoodSelection,
        ),
        title: Text(
          'How are you feeling?',
          style: GoogleFonts.lexend(
            color: const Color(0xFF4F372D),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : _skipMoodSelection,
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                color: const Color(0xFF9C6644),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C6644)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your mood',
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4F372D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps you track your emotional patterns over time',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF4F372D).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Mood grid
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _moodOptions.map((mood) {
                      return _buildMoodButton(
                        emoji: mood['emoji']!,
                        name: mood['name']!,
                        description: mood['description']!,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMoodButton({
    required String emoji,
    required String name,
    required String description,
  }) {
    return GestureDetector(
      onTap: () => _selectMood(name),
      child: Container(
        width: (MediaQuery.of(context).size.width - 80) / 2, // Two columns with spacing
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F372D).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4F372D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF4F372D).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
