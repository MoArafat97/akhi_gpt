import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../services/hive_service.dart';
import '../models/journal_entry.dart';

class NewNotePage extends StatefulWidget {
  const NewNotePage({super.key});

  @override
  State<NewNotePage> createState() => _NewNotePageState();
}

class _NewNotePageState extends State<NewNotePage> {
  final HiveService _hiveService = HiveService.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Set up auto-save listeners
    _titleController.addListener(_autoSave);
    _contentController.addListener(_autoSave);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _autoSave() {
    if (_isSaving) return;

    // Auto-save to temporary storage
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isNotEmpty || content.trim().isNotEmpty) {
      developer.log('Auto-saving note: $title', name: 'NewNotePage');
      // Note: We'll save the final entry only when user taps Save
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a title or content before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create journal entry with current date/time
      final entry = JournalEntry(
        title: title.isEmpty ? 'Untitled' : title,
        content: content.isEmpty ? 'No content' : content,
      );

      // Save to Hive
      final entryKey = await _hiveService.addEntry(entry);
      developer.log('Saved journal entry with key: $entryKey', name: 'NewNotePage');

      if (mounted) {
        // Navigate back with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      developer.log('Error saving entry: $e', name: 'NewNotePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4F372D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Journal Entry',
          style: GoogleFonts.lexend(
            color: const Color(0xFF4F372D),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C6644)),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF9C6644)),
              onPressed: _saveEntry,
              tooltip: 'Save Entry',
            ),
        ],
      ),
      body: Column(
        children: [
          // Title input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _titleController,
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4F372D),
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F372D).withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: const Color(0xFF4F372D).withValues(alpha: 0.1),
          ),

          // Content editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.inter(
                  color: const Color(0xFF4F372D),
                  fontSize: 16,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing your thoughts...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF4F372D).withValues(alpha: 0.4),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


