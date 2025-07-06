import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../services/hive_service.dart';
import '../models/anonymous_letter.dart';
import '../utils/error_handler.dart';

class LetterPage extends StatefulWidget {
  final Color bgColor;

  const LetterPage({super.key, this.bgColor = const Color(0xFFA8B97F)});

  @override
  State<LetterPage> createState() => _LetterPageState();
}

class _LetterPageState extends State<LetterPage> {
  final HiveService _hiveService = HiveService.instance;
  final TextEditingController _letterController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Start with empty text field
    _letterController.text = '';
  }

  @override
  void dispose() {
    _letterController.dispose();
    _focusNode.dispose();
    super.dispose();
  }



  Future<void> _saveLetter() async {
    if (_isSaving) return;
    
    final letterText = _letterController.text.trim();

    // Check if user has written anything
    if (letterText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your message before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create anonymous letter
      final letter = AnonymousLetter(
        text: letterText,
      );

      // Save to Hive
      await _hiveService.addLetter(letter);
      developer.log('Saved anonymous letter', name: 'LetterPage');

      if (mounted) {
        // Show success message
        ErrorHandler.showSuccessSnackBar(
          context,
          'Letter saved privately',
          duration: const Duration(seconds: 2),
        );

        // Navigate back with success result
        Navigator.pop(context, true);
      }
    } catch (e) {
      developer.log('Error saving letter: $e', name: 'LetterPage');
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Unable to save letter. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        backgroundColor: widget.bgColor.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Letter to Allah',
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [

        ],
      ),
      body: Column(
        children: [
          // Letter writing area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
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
              child: TextField(
                controller: _letterController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                style: GoogleFonts.inter(
                  color: const Color(0xFF4F372D),
                  fontSize: 16,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Write your anonymous message here...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF4F372D).withValues(alpha: 0.4),
                    fontSize: 16,
                    height: 1.6,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(24),
                ),
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLetter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.bgColor,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(widget.bgColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Saving...',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send,
                            size: 20,
                            color: widget.bgColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Send & Auto-burn in 24h',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
