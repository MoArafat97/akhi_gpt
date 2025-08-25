import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import '../utils/gender_util.dart';
import '../utils/secure_logger.dart';
import '../utils/error_handler.dart';
import '../config/personality_config.dart';
import 'islamic_context_analyzer.dart';
import 'islamic_reminder_service.dart';
import 'secure_network_service.dart';
import 'input_validation_service.dart';

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  // Proxy configuration - when enabled, routes through enhanced proxy
  static String? get _proxyEndpoint => dotenv.env['PROXY_ENDPOINT'];
  static bool get _useProxy => dotenv.env['ENABLE_PROXY']?.toLowerCase() == 'true';

  // Fixed model - loaded from environment
  static const String _fixedModelDisplayName = 'Companion Assistant';

  // Models are now dynamically fetched based on user's API key
  // No hardcoded fallback models - user must select from available models

  // Storage keys
  static const String _lastWorkingModelKey = 'last_working_model';
  static const String _modelFailureCountKey = 'model_failure_count';

  // Secure storage instance
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Dynamic system prompt based on personality settings
  static Future<String> _getSystemPrompt(UserGender gender) async {
    final companionName = await GenderUtil.getCompanionName();
    final personalityStyle = await GenderUtil.getEffectivePersonalityStyle();
    final isMale = gender == UserGender.male;
    final relationshipType = isMale ? 'big brother' : 'big sister';

    // Get personality-specific language style
    final languageStyle = await PersonalityLanguageConfig.getLanguageStyle(personalityStyle, isMale);
    final responseStyle = PersonalityLanguageConfig.getResponseStyle(personalityStyle);

    return '''You are $companionName, a caring Muslim companion who genuinely cares about the person you're talking to. Think of yourself as the $relationshipType they've always needed - someone who truly listens, understands, and offers both emotional support and spiritual guidance when it feels right.

$languageStyle

Your approach to conversation:
You're naturally empathetic and emotionally intelligent. When someone shares something with you, you instinctively pick up on the feelings behind their words, not just the surface meaning. If someone says "life is treating me like shit," you hear the pain and overwhelm, not offensive language. You respond to their emotional state with genuine care and curiosity about what's really going on.

$responseStyle

You understand that people express distress in different ways. Strong language often signals someone is struggling and needs support, not judgment. You stay focused on understanding their experience and offering meaningful help rather than policing their word choices.

Your personality naturally blends:
- Genuine warmth without being overly cheerful
- Spiritual wisdom that feels authentic, not preachy
- The ability to ask the right questions to understand what someone really needs
- Confidence in your faith while respecting where others are in their journey
- Natural conversation flow that feels like talking to a real friend

When Islamic guidance feels relevant, you share it from the heart - maybe a verse that genuinely helped you understand something, or a perspective from Islamic teachings that brings comfort. You never force it or make it feel like a lecture.

For serious concerns:
If someone mentions wanting to die, self-harm, or expresses suicidal thoughts, you immediately prioritize their safety. You express genuine concern, encourage them to reach out to someone they trust, and provide crisis resources (like Samaritans: 116 123 in the UK). You remind them they're not alone and that Allah sees them, but you make it clear they need professional support.

You avoid giving medical or legal advice, and you don't try to be a therapist. You're simply a caring companion who listens well, offers emotional support, and shares spiritual perspective when it feels natural and helpful.

Remember: You're having a real conversation with a real person. Be present, be genuine, and let your responses flow naturally from understanding what they're going through. Keep your replies conversational - usually 2-4 sentences that show you're really listening, followed by a caring question that invites them to share more.

Important boundaries:
While you're naturally understanding and patient, you do maintain respect in conversations. If someone becomes genuinely aggressive, disrespectful about religion, or repeatedly hostile after you've tried to understand and help, you can gently but firmly redirect: "I want to help, but let's keep this respectful." If the behavior continues, you may need to pause the conversation temporarily.

Your goal isn't to be perfect - it's to be real, caring, and genuinely helpful to someone who might be struggling.''';
  }

  /// Build contextual Islamic guidance based on message analysis
  static String _buildIslamicContextGuidance(IslamicContextAnalysis analysis, UserGender gender) {
    if (analysis.detectedContext == null) return '';

    final genderTerm = gender == UserGender.male ? 'akhi' : 'ukhti';
    final contextualGuidance = StringBuffer('\n\nContextual Islamic Guidance:\n');

    switch (analysis.detectedContext) {
      case 'gratitude':
        contextualGuidance.write('The user is expressing gratitude. This is a perfect moment to naturally acknowledge Allah\'s blessings. Consider using "Alhamdulillah" or "SubhanAllah" if it feels authentic to your response.');
        break;
      case 'difficulty':
        contextualGuidance.write('The user is going through difficulty. This is when Islamic wisdom about patience (sabr) and trust in Allah (tawakkul) can be most comforting. Consider gentle reminders like "Sabr $genderTerm" or "Allah knows best" if appropriate.');
        break;
      case 'hope':
        contextualGuidance.write('The user is expressing hope or future aspirations. This is a natural time to use "Insha\'Allah" or remind them to trust in Allah\'s plan.');
        break;
      case 'uncertainty':
        contextualGuidance.write('The user is feeling uncertain or confused. Islamic guidance about seeking Allah\'s guidance through dua and having tawakkul (trust) in Allah can be very comforting here.');
        break;
    }

    if (analysis.recommendedExpression != null) {
      contextualGuidance.write(' Suggested expression: "${analysis.recommendedExpression}"');
    }

    contextualGuidance.write('\n\nRemember: Only use these expressions if they feel natural and authentic to your response. Don\'t force them.');

    return contextualGuidance.toString();
  }

  final Dio _dio;
  final Dio? _proxyDio;

  OpenRouterService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://nafs-ai.app',
            'X-Title': 'NafsAI',
          },
        )),
        _proxyDio = _useProxy && _proxyEndpoint != null
          ? Dio(BaseOptions(
              baseUrl: _proxyEndpoint!,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              headers: {
                'Content-Type': 'application/json',
                'X-User-ID': 'flutter-client',
              },
            ))
          : null;

  // Proxy-only mode: no client-side API key

  // Proxy-only mode: model selection handled server-side via DEFAULT_MODEL/FALLBACK_MODELS

  /// Get the model name for display (dynamic based on personality settings)
  Future<String> getModelDisplayName() async {
    final companionName = await GenderUtil.getCompanionName();
    return '$companionName Assistant';
  }

  /// Get the model name for display (legacy sync version)
  String get modelDisplayName => _fixedModelDisplayName;

  /// Check if service is properly configured
  Future<bool> get isConfigured async {
    final hasProxy = _useProxy && _proxyDio != null;
    final hasDirectKey = dotenv.env['OPENROUTER_API_KEY']?.isNotEmpty == true;
    return hasProxy || hasDirectKey;
  }

  /// Legacy sync version - always returns false since we need async user API key check
  bool get isConfiguredSync {
    // Cannot check user API key synchronously, always return false
    // Use isConfigured (async) instead
    return false;
  }

  /// Check if an error indicates rate limiting or model unavailability
  bool _isRateLimitOrModelError(dynamic error) {
    if (error is DioException) {
      // Check HTTP status codes
      if (error.response?.statusCode == 429) return true; // Rate limit
      if (error.response?.statusCode == 503) return true; // Service unavailable
      if (error.response?.statusCode == 502) return true; // Bad gateway

      // Check OpenRouter specific error messages
      final errorData = error.response?.data;
      if (errorData is Map) {
        final errorMessage = errorData['error']?.toString().toLowerCase() ?? '';
        final errorType = errorData['type']?.toString().toLowerCase() ?? '';

        return errorMessage.contains('rate limit') ||
               errorMessage.contains('quota') ||
               errorMessage.contains('unavailable') ||
               errorType.contains('rate_limit') ||
               errorType.contains('quota_exceeded');
      }
    }
    return false;
  }

  /// Sanitize AI assistant content to remove formatting artifacts and internal notes
  String _sanitizeContent(String content) {
    // 1. Remove asterisks that slip through from LLM formatting
    var sanitized = content.replaceAll('*', '');

    // 2. Remove any parenthetical instructions about self-harm or crisis handling
    sanitized = sanitized.replaceAll(
      RegExp(r'\([^)]*(self[- ]?harm|suicid|crisis)[^)]*\)', caseSensitive: false),
      '',
    );

    // 3. Strip role-style tags like "<| Assistant |>", "<|system|>", etc.
    sanitized = sanitized.replaceAll(RegExp(r'^<\|[^>]+\|>\s*'), '');

    // 4. Remove one-line internal headings / notes that sometimes appear
    sanitized = sanitized.replaceAll(
      RegExp(r'^(?:🚫|ABSOLUTE PROHIBITION|MANDATORY|Follow-up|Key elements|Note):?[^\n]*',
          caseSensitive: false, multiLine: true),
      '',
    );

    // 5. Remove any parenthetical blocks that look like meta commentary (6+ words)
    sanitized = sanitized.replaceAll(
      RegExp(r'\((?:[^)]*?\s){6,}[^)]*?\)', multiLine: true),
      '',
    );

    // 6. Replace remaining newlines with spaces to keep natural flow
    sanitized = sanitized.replaceAll('\n', ' ');

    // 7. Collapse multiple spaces while preserving single leading space if present
    sanitized = sanitized.replaceAll(RegExp(r' {2,}'), ' ');

    // 8. Trim only the right side so leading space (if any) is preserved, avoiding word-jamming across chunks
    return sanitized.trimRight();
  }

  /// Get the next fallback model is handled server-side in proxy-only mode
  Future<String?> _getNextFallbackModel(String currentModel) async {
    developer.log('Client fallback selection disabled; handled by proxy', name: 'OpenRouterService');
    return null;
  }

  /// Mark a model as working and save it as the last working model
  Future<void> _markModelAsWorking(String model) async {
    await _secureStorage.write(key: _lastWorkingModelKey, value: model);
    await _secureStorage.delete(key: _modelFailureCountKey);
    developer.log('Marked model as working: $model', name: 'OpenRouterService');
  }

  /// Switch to the next fallback model
  Future<String?> _switchToFallbackModel(String failedModel) async {
    final nextModel = await _getNextFallbackModel(failedModel);
    if (nextModel != null) {
      await _secureStorage.write(key: _lastWorkingModelKey, value: nextModel);
      developer.log('Switched from $failedModel to fallback: $nextModel', name: 'OpenRouterService');
    }
    return nextModel;
  }

  /// Test connection to OpenRouter API (direct or proxy)
  Future<bool> testConnection() async {
    try {
      if (!(await isConfigured)) {
        developer.log('Service not configured', name: 'OpenRouterService');
        return false;
      }

      // Test proxy if enabled, otherwise test direct OpenRouter API
      if (_useProxy && _proxyDio != null) {
        final proxyStatus = await testProxyConnection();
        if (proxyStatus) {
          developer.log('Proxy connection successful', name: 'OpenRouterService');
          return true;
        }
        developer.log('Proxy connection failed', name: 'OpenRouterService');
        return false;
      } else {
        // Test direct OpenRouter API connection
        final directStatus = await testDirectConnection();
        if (directStatus) {
          developer.log('Direct OpenRouter API connection successful', name: 'OpenRouterService');
          return true;
        }
        developer.log('Direct OpenRouter API connection failed', name: 'OpenRouterService');
        return false;
      }
    } catch (e) {
      developer.log('Connection test failed: $e', name: 'OpenRouterService');
      return false;
    }
  }

  /// Test proxy connection and get status
  Future<bool> testProxyConnection() async {
    if (_proxyDio == null) return false;

    try {
      final response = await _proxyDio!.get('/status');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Proxy status check failed: $e', name: 'OpenRouterService');
      return false;
    }
  }

  /// Test direct OpenRouter API connection
  Future<bool> testDirectConnection() async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      developer.log('❌ No API key available for direct connection test', name: 'OpenRouterService');
      return false;
    }

    try {
      developer.log('🔍 Testing direct connection with API key: ${apiKey.substring(0, 20)}...', name: 'OpenRouterService');

      // Test with a simple models endpoint call
      final response = await _dio.get(
        '/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://github.com/MoArafat97/akhi_gpt',
            'X-Title': 'Akhi GPT',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      developer.log('📥 Models endpoint response: ${response.statusCode}', name: 'OpenRouterService');

      // Only 200 means the connection is truly working
      final isConnected = response.statusCode == 200;
      developer.log('🔍 Direct API test result: ${response.statusCode} - ${isConnected ? "✅ Connected" : "❌ Failed"}', name: 'OpenRouterService');

      // Log specific issues for non-200 responses
      if (response.statusCode == 401) {
        developer.log('❌ API key is invalid or expired', name: 'OpenRouterService');
      } else if (response.statusCode == 429) {
        developer.log('⚠️ Rate limited - will try fallback models', name: 'OpenRouterService');
      }

      if (response.statusCode == 200) {
        // Test with the actual model we'll use
        final model = dotenv.env['DEFAULT_MODEL'];
        developer.log('🔍 Testing chat completions with model: $model', name: 'OpenRouterService');

        try {
          final chatResponse = await _dio.post(
            '/chat/completions',
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://github.com/MoArafat97/akhi_gpt',
                'X-Title': 'Akhi GPT',
              },
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
            data: {
              'model': model,
              'messages': [
                {'role': 'user', 'content': 'Test connection'}
              ],
              'max_tokens': 10,
            },
          );

          developer.log('📥 Chat completions test: ${chatResponse.statusCode}', name: 'OpenRouterService');
          if (chatResponse.statusCode == 200) {
            developer.log('✅ Chat completions working with model: $model', name: 'OpenRouterService');
          } else {
            developer.log('⚠️ Chat completions failed: ${chatResponse.statusCode} - ${chatResponse.data}', name: 'OpenRouterService');
          }
        } catch (chatError) {
          developer.log('❌ Chat completions test failed: $chatError', name: 'OpenRouterService');
        }
      }

      return isConnected;
    } catch (e) {
      developer.log('❌ Direct API connection test failed: $e', name: 'OpenRouterService');
      if (e is DioException) {
        developer.log('   Status code: ${e.response?.statusCode}', name: 'OpenRouterService');
        developer.log('   Response data: ${e.response?.data}', name: 'OpenRouterService');
        developer.log('   Error type: ${e.type}', name: 'OpenRouterService');
      }
      return false;
    }
  }

  /// Get proxy status information
  Future<Map<String, dynamic>?> getProxyStatus() async {
    if (_proxyDio == null) return null;

    try {
      final response = await _proxyDio!.get('/status');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      developer.log('Failed to get proxy status: $e', name: 'OpenRouterService');
    }
    return null;
  }

  /// Stream chat responses either via proxy (if enabled) or directly to OpenRouter using .env API key
  Stream<String> chatStream(String message, List<ChatMessage> history, {UserGender? gender}) async* {
    // Get user gender (default to male for backward compatibility)
    final userGender = gender ?? await GenderUtil.getUserGender();

    // Analyze message for Islamic context
    final islamicAnalysis = IslamicContextAnalyzer.analyzeMessage(message);
    final shouldIncludeReminder = IslamicReminderService.shouldIncludeReminder();

    // Build messages starting with system prompt
    final messages = <Map<String, String>>[];
    final systemPrompt = await _getSystemPrompt(userGender);

    // Enhance system prompt with contextual Islamic guidance if appropriate
    String enhancedSystemPrompt = systemPrompt;
    if (islamicAnalysis.shouldIncludeIslamic || (shouldIncludeReminder && islamicAnalysis.isHighPriorityContext)) {
      enhancedSystemPrompt += _buildIslamicContextGuidance(islamicAnalysis, userGender);
    }

    messages.add({'role': 'system', 'content': enhancedSystemPrompt});
    for (final msg in history) {
      if (msg.role == 'system') continue;
      messages.add(msg.toMap());
    }
    messages.add({'role': 'user', 'content': message});

    // Prefer proxy if configured
    if (_proxyDio != null && _useProxy) {
      developer.log('Using proxy for chat stream', name: 'OpenRouterService');
      try {
        await for (final chunk in _chatStreamViaProxy(messages)) {
          yield chunk;
        }
        return;
      } catch (e) {
        developer.log('Proxy stream failed, attempting direct: $e', name: 'OpenRouterService');
        // Fall through to direct
      }
    }

    // Direct OpenRouter call using API key from .env
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      developer.log('No API key available for direct connection', name: 'OpenRouterService');
      // No key available; provide local fallback
      yield* _getLocalFallbackResponse(userGender);
      return;
    }

    developer.log('Using direct OpenRouter API with key: ${apiKey.substring(0, 20)}...', name: 'OpenRouterService');

    // Try primary model first, then fallbacks
    final models = [
      dotenv.env['DEFAULT_MODEL'],
      ...dotenv.env['FALLBACK_MODELS']?.split(',') ?? [],
    ].where((m) => m != null && m.isNotEmpty).cast<String>().toList();

    developer.log('Available models for fallback: $models', name: 'OpenRouterService');

    for (int i = 0; i < models.length; i++) {
      final model = models[i];
      developer.log('Trying model ${i + 1}/${models.length}: $model', name: 'OpenRouterService');

      try {
        bool hasYieldedContent = false;
        await for (final chunk in _chatStreamDirectWithModel(messages, apiKey, model)) {
          hasYieldedContent = true;
          yield chunk;
        }

        // If we successfully yielded content, we're done
        if (hasYieldedContent) {
          developer.log('✅ Successfully completed with model: $model', name: 'OpenRouterService');
          return;
        }
      } catch (e) {
        developer.log('❌ Model $model failed: $e', name: 'OpenRouterService');

        // Check if this is a rate limit or model-specific error
        if (e is DioException && e.response?.statusCode == 429) {
          developer.log('⚠️ Rate limited on $model, trying next model...', name: 'OpenRouterService');
          continue;
        }

        // For other errors, try next model
        if (i < models.length - 1) {
          developer.log('🔄 Trying next model...', name: 'OpenRouterService');
          continue;
        }
      }
    }

    // All models failed, provide local fallback
    developer.log('❌ All models failed, providing local fallback', name: 'OpenRouterService');
    yield* _getLocalFallbackResponse(userGender);
  }

  /// Stream chat responses via enhanced proxy
  Stream<String> _chatStreamViaProxy(List<Map<String, String>> messages) async* {
    if (_proxyDio == null) {
      throw Exception('Proxy not configured');
    }

    try {
      developer.log('Sending request to enhanced proxy', name: 'OpenRouterService');

      // Extract the user prompt from messages
      final userMessage = messages.lastWhere((msg) => msg['role'] == 'user');
      final history = messages.where((msg) => msg['role'] != 'user').toList();

      final response = await _proxyDio!.post(
        '/', // Proxy endpoint
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'history': history,
          'prompt': userMessage['content'],
        },
      );

      developer.log('Proxy response status: ${response.statusCode}', name: 'OpenRouterService');

      final stream = response.data.stream as Stream<Uint8List>;
      String buffer = '';

      await for (final chunk in stream) {
        final chunkStr = utf8.decode(chunk, allowMalformed: true);
        buffer += chunkStr;

        // Process complete lines
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            developer.log('Received proxy data: $data', name: 'OpenRouterService');

            if (data == '[DONE]') {
              developer.log('Proxy stream completed', name: 'OpenRouterService');
              return;
            }

            if (data.isNotEmpty && data != '[DONE]') {
              try {
                final json = jsonDecode(data);
                final choices = json['choices'] as List?;

                if (choices != null && choices.isNotEmpty) {
                  final delta = choices[0]['delta'] as Map<String, dynamic>?;
                  final content = delta?['content'] as String?;

                  if (content != null && content.isNotEmpty) {
                    final sanitized = _sanitizeContent(content);
                    if (sanitized.isNotEmpty) {
                      developer.log('Yielding proxy content: $sanitized', name: 'OpenRouterService');
                      yield sanitized;
                    }
                  }
                }
              } catch (e) {
                // Skip malformed JSON chunks
                developer.log('Failed to parse proxy chunk: $e', name: 'OpenRouterService');
                continue;
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Proxy stream error: $e', name: 'OpenRouterService');
      rethrow;
    }
  }

  /// Direct OpenRouter streaming using SSE (legacy method for backward compatibility)
  Stream<String> _chatStreamDirect(List<Map<String, String>> messages, String apiKey) async* {
    final model = dotenv.env['DEFAULT_MODEL'] ?? 'qwen/qwen3-coder:free';
    yield* _chatStreamDirectWithModel(messages, apiKey, model);
  }

  /// Direct OpenRouter streaming using SSE with specific model
  Stream<String> _chatStreamDirectWithModel(List<Map<String, String>> messages, String apiKey, String model) async* {
    try {
      developer.log('🚀 Starting direct OpenRouter stream with model: $model', name: 'OpenRouterService');
      developer.log('🔑 Using API key: ${apiKey.substring(0, 20)}...', name: 'OpenRouterService');
      developer.log('📝 Messages count: ${messages.length}', name: 'OpenRouterService');

      final requestData = {
        'model': model,
        'messages': messages,
        'stream': true,
        'max_tokens': 512,
      };

      developer.log('📤 Request data: $requestData', name: 'OpenRouterService');

      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'Accept': 'text/event-stream',
            'HTTP-Referer': 'https://github.com/MoArafat97/akhi_gpt',
            'X-Title': 'Akhi GPT',
          },
          responseType: ResponseType.stream,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: requestData,
      );

      developer.log('📥 Response status: ${response.statusCode}', name: 'OpenRouterService');
      developer.log('📥 Response headers: ${response.headers}', name: 'OpenRouterService');

      developer.log('Direct stream response status: ${response.statusCode}', name: 'OpenRouterService');

      final stream = response.data.stream as Stream<Uint8List>;
      String buffer = '';
      await for (final chunk in stream) {
        final chunkStr = utf8.decode(chunk, allowMalformed: true);
        buffer += chunkStr;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            if (data.isEmpty) continue;
            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  final sanitized = _sanitizeContent(content);
                  if (sanitized.isNotEmpty) yield sanitized;
                }
              }
            } catch (_) {
              continue; // skip malformed chunks
            }
          }
        }
      }
    } catch (e) {
      developer.log('❌ Direct OpenRouter stream error with model $model: $e', name: 'OpenRouterService');
      if (e is DioException) {
        developer.log('❌ DioException details:', name: 'OpenRouterService');
        developer.log('   Status code: ${e.response?.statusCode}', name: 'OpenRouterService');
        developer.log('   Response data: ${e.response?.data}', name: 'OpenRouterService');
        developer.log('   Error type: ${e.type}', name: 'OpenRouterService');
        developer.log('   Error message: ${e.message}', name: 'OpenRouterService');

        // Handle specific error cases
        if (e.response?.statusCode == 429) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData['error'] != null) {
            final errorMessage = errorData['error']['message'] ?? 'Rate limited';
            developer.log('⚠️ Rate limit details: $errorMessage', name: 'OpenRouterService');
          }
        }
      }
      rethrow;
    }
  }

  /// Provide a local fallback response when all models are unavailable
  Stream<String> _getLocalFallbackResponse(UserGender gender) async* {
    developer.log('Providing local fallback response for ${gender.displayName}', name: 'OpenRouterService');

    final fallbackMessage = '''Hey ${gender.casualAddress}, I'm having some technical difficulties right now, but I'm still here for you. 🤲

While I sort this out, remember that Allah (SWT) is always with you, even in the hardest moments. Take a deep breath, make du'a, and know that this too shall pass.

If you're in crisis or need immediate help, please reach out to:
🇬🇧 UK: Samaritans - 116 123 (free, 24/7)
🌍 Or your local emergency services

I'll be back to full capacity soon, insha'Allah. Stay strong, ${gender.formalAddress}. 💙''';

    // Simulate typing effect for natural feel
    final words = fallbackMessage.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (i == 0) {
        yield words[i];
      } else {
        yield ' ${words[i]}';
      }

      // Small delay between words to simulate natural typing
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

}

