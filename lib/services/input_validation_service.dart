import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

/// Comprehensive input validation service to prevent injection attacks and ensure data integrity
class InputValidationService {
  static const int _maxMessageLength = 10000;
  static const int _maxTitleLength = 200;
  static const int _maxNameLength = 100;

  /// Validate and sanitize chat message input
  static ValidationResult validateChatMessage(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: '',
        error: 'Message cannot be empty',
      );
    }

    final trimmed = input.trim();
    
    // Check length
    if (trimmed.length > _maxMessageLength) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: trimmed.substring(0, _maxMessageLength),
        error: 'Message too long (max $_maxMessageLength characters)',
      );
    }

    // Check for malicious patterns
    final maliciousPatterns = [
      r'<script[^>]*>.*?</script>',
      r'javascript:',
      r'vbscript:',
      r'onload\s*=',
      r'onerror\s*=',
      r'onclick\s*=',
      r'data:text/html',
    ];

    for (final pattern in maliciousPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(trimmed)) {
        SecureLogger.warning('Malicious pattern detected in chat message', name: 'InputValidation');
        return ValidationResult(
          isValid: false,
          sanitizedValue: _sanitizeString(trimmed),
          error: 'Message contains potentially harmful content',
        );
      }
    }

    // Sanitize the input
    final sanitized = _sanitizeString(trimmed);
    
    return ValidationResult(
      isValid: true,
      sanitizedValue: sanitized,
    );
  }

  /// Validate and sanitize title input (for journal entries, etc.)
  static ValidationResult validateTitle(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: '',
        error: 'Title cannot be empty',
      );
    }

    final trimmed = input.trim();
    
    if (trimmed.length > _maxTitleLength) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: trimmed.substring(0, _maxTitleLength),
        error: 'Title too long (max $_maxTitleLength characters)',
      );
    }

    final sanitized = _sanitizeString(trimmed);
    
    return ValidationResult(
      isValid: true,
      sanitizedValue: sanitized,
    );
  }

  /// Validate and sanitize name input
  static ValidationResult validateName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: '',
        error: 'Name cannot be empty',
      );
    }

    final trimmed = input.trim();
    
    if (trimmed.length > _maxNameLength) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: trimmed.substring(0, _maxNameLength),
        error: 'Name too long (max $_maxNameLength characters)',
      );
    }

    // Names should only contain letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmed)) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: _sanitizeString(trimmed),
        error: 'Name contains invalid characters',
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
    );
  }

  /// Validate email format (if needed)
  static ValidationResult validateEmail(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: '',
        error: 'Email cannot be empty',
      );
    }

    final trimmed = input.trim().toLowerCase();
    
    // Basic email regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(trimmed)) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: trimmed,
        error: 'Invalid email format',
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
    );
  }

  /// Validate URL format
  static ValidationResult validateUrl(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: '',
        error: 'URL cannot be empty',
      );
    }

    final trimmed = input.trim();
    
    // Only allow HTTPS URLs for security
    if (!trimmed.startsWith('https://')) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: trimmed,
        error: 'Only HTTPS URLs are allowed',
      );
    }

    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasAbsolutePath) {
        return ValidationResult(
          isValid: false,
          sanitizedValue: trimmed,
          error: 'Invalid URL format',
        );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: trimmed,
        error: 'Invalid URL format',
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
    );
  }

  /// Sanitize string by removing potentially harmful characters
  static String _sanitizeString(String input) {
    return input
        // Remove HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Remove script-related content
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'vbscript:', caseSensitive: false), '')
        // Remove control characters except newlines and tabs
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        // Remove excessive whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Check if string contains only safe characters for display
  static bool isSafeForDisplay(String input) {
    // Allow letters, numbers, common punctuation, and whitespace
    return RegExp(r'^[a-zA-Z0-9\s\.,!?;:()\[\]{}\-_+=@#$%^&*~`"\'\/\\|<>]*$').hasMatch(input);
  }

  /// Validate JSON structure to prevent malformed data
  static ValidationResult validateJsonStructure(Map<String, dynamic>? data) {
    if (data == null) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: <String, dynamic>{},
        error: 'Data cannot be null',
      );
    }

    try {
      // Check for reasonable nesting depth (prevent stack overflow)
      if (_getNestedDepth(data) > 10) {
        return ValidationResult(
          isValid: false,
          sanitizedValue: <String, dynamic>{},
          error: 'Data structure too deeply nested',
        );
      }

      // Check for reasonable size (prevent memory exhaustion)
      final jsonString = data.toString();
      if (jsonString.length > 100000) { // 100KB limit
        return ValidationResult(
          isValid: false,
          sanitizedValue: <String, dynamic>{},
          error: 'Data structure too large',
        );
      }

      return ValidationResult(
        isValid: true,
        sanitizedValue: data,
      );
    } catch (e) {
      SecureLogger.error('JSON validation error', name: 'InputValidation', error: e);
      return ValidationResult(
        isValid: false,
        sanitizedValue: <String, dynamic>{},
        error: 'Invalid data structure',
      );
    }
  }

  /// Get the nested depth of a data structure
  static int _getNestedDepth(dynamic data, [int currentDepth = 0]) {
    if (currentDepth > 20) return currentDepth; // Prevent infinite recursion

    if (data is Map) {
      int maxDepth = currentDepth;
      for (final value in data.values) {
        final depth = _getNestedDepth(value, currentDepth + 1);
        if (depth > maxDepth) maxDepth = depth;
      }
      return maxDepth;
    } else if (data is List) {
      int maxDepth = currentDepth;
      for (final item in data) {
        final depth = _getNestedDepth(item, currentDepth + 1);
        if (depth > maxDepth) maxDepth = depth;
      }
      return maxDepth;
    }

    return currentDepth;
  }
}

/// Result of input validation
class ValidationResult {
  final bool isValid;
  final dynamic sanitizedValue;
  final String? error;

  ValidationResult({
    required this.isValid,
    required this.sanitizedValue,
    this.error,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, error: $error)';
  }
}
