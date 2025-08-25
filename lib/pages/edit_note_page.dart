/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../services/hive_service.dart';
import '../models/journal_entry.dart';

class EditNotePage extends StatefulWidget {
  final JournalEntry entry;

  const EditNotePage({super.key, required this.entry});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final HiveService _hiveService = HiveService.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing entry data
    _titleController.text = widget.entry.title;
    _contentController.text = widget.entry.content;

    // Set up change listeners
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
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
      // Update the existing entry
      final updatedEntry = widget.entry.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: content.isEmpty ? 'No content' : content,
      );

      // Save to Hive
      await _hiveService.updateEntry(updatedEntry);
      developer.log('Updated journal entry with key: ${updatedEntry.key}', name: 'EditNotePage');

      if (mounted) {
        setState(() => _hasChanges = false);
        // Navigate back with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      developer.log('Error updating entry: $e', name: 'EditNotePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating entry: $e'),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4F372D)),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Edit Journal Entry',
            style: GoogleFonts.lexend(
              color: const Color(0xFF4F372D),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isSaving ? null : _saveEntry,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F372D)),
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.lexend(
                          color: const Color(0xFF4F372D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
      ),
    );
  }
}
*/
