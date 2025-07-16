import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:developer' as developer;

/// Enhanced error handling utility for OpenRouter API interactions
class ErrorHandler {
  
  /// Analyze and categorize errors for better user feedback
  static ErrorAnalysis analyzeError(dynamic error) {
    developer.log('🔍 Analyzing error: ${error.runtimeType}', name: 'ErrorHandler');
    
    if (error is DioException) {
      return _analyzeDioException(error);
    } else if (error is Exception) {
      return _analyzeGenericException(error);
    } else {
      return ErrorAnalysis(
        category: ErrorCategory.unknown,
        severity: ErrorSeverity.high,
        userMessage: 'An unexpected error occurred',
        technicalDetails: error.toString(),
        shouldRetry: false,
        shouldFallback: false,
      );
    }
  }
  
  /// Analyze Dio-specific exceptions
  static ErrorAnalysis _analyzeDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final errorData = error.response?.data;
    
    developer.log('🔍 DioException - Status: $statusCode, Type: ${error.type}', name: 'ErrorHandler');
    
    // Network-related errors
    if (error.type == DioExceptionType.connectionTimeout) {
      return ErrorAnalysis(
        category: ErrorCategory.network,
        severity: ErrorSeverity.medium,
        userMessage: 'Connection timed out. Please check your internet connection.',
        technicalDetails: 'Connection timeout: ${error.message}',
        shouldRetry: true,
        shouldFallback: true,
        retryDelay: const Duration(seconds: 5),
      );
    }
    
    if (error.type == DioExceptionType.receiveTimeout) {
      return ErrorAnalysis(
        category: ErrorCategory.network,
        severity: ErrorSeverity.medium,
        userMessage: 'Server response timed out. The service might be busy.',
        technicalDetails: 'Receive timeout: ${error.message}',
        shouldRetry: true,
        shouldFallback: true,
        retryDelay: const Duration(seconds: 3),
      );
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return ErrorAnalysis(
        category: ErrorCategory.network,
        severity: ErrorSeverity.high,
        userMessage: 'Unable to connect to the service. Please check your internet connection.',
        technicalDetails: 'Connection error: ${error.message}',
        shouldRetry: true,
        shouldFallback: false,
        retryDelay: const Duration(seconds: 10),
      );
    }
    
    // HTTP status code based analysis
    if (statusCode != null) {
      return _analyzeHttpStatus(statusCode, errorData, error);
    }
    
    // Fallback for other Dio exceptions
    return ErrorAnalysis(
      category: ErrorCategory.api,
      severity: ErrorSeverity.medium,
      userMessage: 'Service temporarily unavailable. Please try again.',
      technicalDetails: 'DioException: ${error.message}',
      shouldRetry: true,
      shouldFallback: true,
    );
  }
  
  /// Analyze HTTP status codes
  static ErrorAnalysis _analyzeHttpStatus(int statusCode, dynamic errorData, DioException error) {
    switch (statusCode) {
      case 400:
        return ErrorAnalysis(
          category: ErrorCategory.client,
          severity: ErrorSeverity.medium,
          userMessage: 'Invalid request. Please try rephrasing your message.',
          technicalDetails: 'HTTP 400: ${_extractErrorMessage(errorData)}',
          shouldRetry: false,
          shouldFallback: false,
        );
        
      case 401:
        return ErrorAnalysis(
          category: ErrorCategory.authentication,
          severity: ErrorSeverity.high,
          userMessage: 'Authentication failed. Please check your API configuration.',
          technicalDetails: 'HTTP 401: Invalid or missing API key',
          shouldRetry: false,
          shouldFallback: false,
          requiresConfiguration: true,
        );
        
      case 403:
        return ErrorAnalysis(
          category: ErrorCategory.authorization,
          severity: ErrorSeverity.high,
          userMessage: 'Access denied. Your API key may lack required permissions.',
          technicalDetails: 'HTTP 403: ${_extractErrorMessage(errorData)}',
          shouldRetry: false,
          shouldFallback: false,
          requiresConfiguration: true,
        );
        
      case 404:
        return ErrorAnalysis(
          category: ErrorCategory.model,
          severity: ErrorSeverity.medium,
          userMessage: 'The AI model is currently unavailable. Trying alternative model...',
          technicalDetails: 'HTTP 404: Model not found or unavailable',
          shouldRetry: false,
          shouldFallback: true,
        );
        
      case 429:
        return ErrorAnalysis(
          category: ErrorCategory.rateLimit,
          severity: ErrorSeverity.medium,
          userMessage: 'Too many requests. Please wait a moment before trying again.',
          technicalDetails: 'HTTP 429: Rate limit exceeded',
          shouldRetry: true,
          shouldFallback: true,
          retryDelay: const Duration(seconds: 30),
        );
        
      case 500:
        return ErrorAnalysis(
          category: ErrorCategory.server,
          severity: ErrorSeverity.medium,
          userMessage: 'Server error. Trying alternative approach...',
          technicalDetails: 'HTTP 500: Internal server error',
          shouldRetry: true,
          shouldFallback: true,
          retryDelay: const Duration(seconds: 5),
        );
        
      case 502:
      case 503:
      case 504:
        return ErrorAnalysis(
          category: ErrorCategory.server,
          severity: ErrorSeverity.medium,
          userMessage: 'Service temporarily unavailable. Trying alternative...',
          technicalDetails: 'HTTP $statusCode: Service unavailable',
          shouldRetry: true,
          shouldFallback: true,
          retryDelay: const Duration(seconds: 10),
        );
        
      default:
        return ErrorAnalysis(
          category: ErrorCategory.api,
          severity: ErrorSeverity.medium,
          userMessage: 'Unexpected server response. Please try again.',
          technicalDetails: 'HTTP $statusCode: ${_extractErrorMessage(errorData)}',
          shouldRetry: true,
          shouldFallback: true,
        );
    }
  }
  
  /// Analyze generic exceptions
  static ErrorAnalysis _analyzeGenericException(Exception error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') || errorString.contains('network')) {
      return ErrorAnalysis(
        category: ErrorCategory.network,
        severity: ErrorSeverity.high,
        userMessage: 'Network connection problem. Please check your internet.',
        technicalDetails: error.toString(),
        shouldRetry: true,
        shouldFallback: false,
      );
    }
    
    if (errorString.contains('timeout')) {
      return ErrorAnalysis(
        category: ErrorCategory.network,
        severity: ErrorSeverity.medium,
        userMessage: 'Request timed out. Please try again.',
        technicalDetails: error.toString(),
        shouldRetry: true,
        shouldFallback: true,
      );
    }
    
    if (errorString.contains('configuration') || errorString.contains('config')) {
      return ErrorAnalysis(
        category: ErrorCategory.configuration,
        severity: ErrorSeverity.high,
        userMessage: 'Configuration error. Please check your settings.',
        technicalDetails: error.toString(),
        shouldRetry: false,
        shouldFallback: false,
        requiresConfiguration: true,
      );
    }
    
    return ErrorAnalysis(
      category: ErrorCategory.unknown,
      severity: ErrorSeverity.medium,
      userMessage: 'An unexpected error occurred. Please try again.',
      technicalDetails: error.toString(),
      shouldRetry: true,
      shouldFallback: true,
    );
  }
  
  /// Extract error message from API response data
  static String _extractErrorMessage(dynamic errorData) {
    if (errorData is Map<String, dynamic>) {
      return errorData['error']?.toString() ?? 
             errorData['message']?.toString() ?? 
             errorData['detail']?.toString() ?? 
             'Unknown error';
    } else if (errorData is String) {
      return errorData;
    } else {
      return errorData?.toString() ?? 'Unknown error';
    }
  }
  
  /// Generate user-friendly error message with context
  static String generateUserMessage(ErrorAnalysis analysis, {String? context}) {
    final buffer = StringBuffer();
    
    if (context != null) {
      buffer.write('$context: ');
    }
    
    buffer.write(analysis.userMessage);
    
    if (analysis.shouldRetry && analysis.retryDelay != null) {
      buffer.write(' Retrying in ${analysis.retryDelay!.inSeconds} seconds...');
    } else if (analysis.shouldFallback) {
      buffer.write(' Trying alternative approach...');
    }
    
    return buffer.toString();
  }
  
  /// Log error with appropriate level
  static void logError(ErrorAnalysis analysis, {String? context}) {
    final contextStr = context != null ? '[$context] ' : '';
    final message = '$contextStr${analysis.category.name.toUpperCase()}: ${analysis.userMessage}';

    switch (analysis.severity) {
      case ErrorSeverity.low:
        developer.log('ℹ️ $message', name: 'ErrorHandler');
        break;
      case ErrorSeverity.medium:
        developer.log('⚠️ $message', name: 'ErrorHandler');
        break;
      case ErrorSeverity.high:
        developer.log('❌ $message', name: 'ErrorHandler');
        break;
    }

    if (analysis.technicalDetails.isNotEmpty) {
      developer.log('🔍 Technical details: ${analysis.technicalDetails}', name: 'ErrorHandler');
    }
  }

  /// Show standardized error SnackBar with optional action
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show standardized success SnackBar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        duration: duration,
      ),
    );
  }

  /// Show standardized warning SnackBar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade600,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Get standardized error message for API configuration issues
  static String getApiConfigurationErrorMessage(ErrorAnalysis analysis) {
    switch (analysis.category) {
      case ErrorCategory.authentication:
        return 'Invalid API key. Please check your OpenRouter configuration in Settings.';
      case ErrorCategory.configuration:
        return 'API not configured. Please add your OpenRouter API key in Settings to start chatting.';
      case ErrorCategory.network:
        return 'Connection issue. Please check your internet connection and try again.';
      case ErrorCategory.rateLimit:
        return 'Rate limit reached. Please wait a moment before trying again.';
      case ErrorCategory.model:
        return 'AI model temporarily unavailable. Trying alternative model...';
      default:
        return 'Service temporarily unavailable. Please try again in a moment.';
    }
  }

  /// Show API configuration error with setup action
  static void showApiConfigurationError(
    BuildContext context,
    ErrorAnalysis analysis,
  ) {
    final message = getApiConfigurationErrorMessage(analysis);

    if (analysis.requiresConfiguration || analysis.category == ErrorCategory.configuration) {
      showErrorSnackBar(
        context,
        message,
        actionLabel: 'Setup',
        onAction: () {
          Navigator.pushNamed(context, '/openrouter_setup');
        },
      );
    } else {
      showErrorSnackBar(context, message);
    }
  }
}

/// Comprehensive error analysis result
class ErrorAnalysis {
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String userMessage;
  final String technicalDetails;
  final bool shouldRetry;
  final bool shouldFallback;
  final Duration? retryDelay;
  final bool requiresConfiguration;
  
  const ErrorAnalysis({
    required this.category,
    required this.severity,
    required this.userMessage,
    required this.technicalDetails,
    required this.shouldRetry,
    required this.shouldFallback,
    this.retryDelay,
    this.requiresConfiguration = false,
  });
  
  @override
  String toString() {
    return 'ErrorAnalysis(category: $category, severity: $severity, shouldRetry: $shouldRetry, shouldFallback: $shouldFallback)';
  }
}

/// Error categories for classification
enum ErrorCategory {
  network,
  authentication,
  authorization,
  rateLimit,
  model,
  server,
  client,
  api,
  configuration,
  unknown,
}

/// Error severity levels
enum ErrorSeverity {
  low,    // Minor issues, user can continue
  medium, // Noticeable issues, but recoverable
  high,   // Serious issues, may require user action
}



/// Subscription-specific error handling methods
extension SubscriptionErrorHandler on ErrorHandler {
  /// Handle RevenueCat purchase errors
  static String handlePurchaseError(dynamic error) {
    if (error is PlatformException) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);

      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          return 'Purchase was cancelled. You can try again anytime.';

        case PurchasesErrorCode.purchaseNotAllowedError:
          return 'Purchases are not allowed on this device. Please check your device settings.';

        case PurchasesErrorCode.purchaseInvalidError:
          return 'This purchase is no longer available. Please try a different option.';

        case PurchasesErrorCode.productNotAvailableForPurchaseError:
          return 'This product is currently unavailable. Please try again later.';

        case PurchasesErrorCode.networkError:
          return 'Network connection error. Please check your internet connection and try again.';

        case PurchasesErrorCode.receiptAlreadyInUseError:
          return 'This purchase has already been used. Try restoring your purchases instead.';

        case PurchasesErrorCode.invalidReceiptError:
          return 'Invalid purchase receipt. Please contact support if this continues.';

        case PurchasesErrorCode.paymentPendingError:
          return 'Payment is pending approval. Please wait and check back later.';

        case PurchasesErrorCode.invalidCredentialsError:
          return 'Invalid credentials. Please contact support.';

        case PurchasesErrorCode.operationAlreadyInProgressError:
          return 'Another purchase is already in progress. Please wait and try again.';

        default:
          developer.log('Unhandled purchase error: ${error.code} - ${error.message}', name: 'SubscriptionErrorHandler');
          return 'Purchase failed: ${error.message ?? 'Unknown error'}';
      }
    }

    return 'An unexpected purchase error occurred: ${error.toString()}';
  }

  /// Handle subscription service initialization errors
  static String handleSubscriptionInitError(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network error during initialization. Some features may be limited.';
    }

    if (error.toString().contains('configuration')) {
      return 'Configuration error. Please check your settings.';
    }

    developer.log('Subscription init error: $error', name: 'SubscriptionErrorHandler');
    return 'Failed to initialize subscription service. Some features may be limited.';
  }

  /// Show subscription error dialog
  static void showSubscriptionErrorDialog(BuildContext context, String title, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }
}
