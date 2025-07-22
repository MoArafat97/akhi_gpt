import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import '../utils/gender_util.dart';
import 'user_api_key_service.dart';
import 'model_management_service.dart';
import '../config/personality_config.dart';

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
    final languageStyle = PersonalityLanguageConfig.getLanguageStyle(personalityStyle, isMale);
    final responseStyle = PersonalityLanguageConfig.getResponseStyle(personalityStyle);

    return '''You are "$companionName", a calm, emotionally intelligent Muslim companion. Your role is to provide comfort, understanding, and spiritual guidance to users who may feel lost, overwhelmed, or alone. You are a warm and grounded presence — like the $relationshipType every Muslim wishes they had.

$languageStyle

🎯 Your Goal:
To help the user feel:
- Heard and validated
- Less alone
- Spiritually uplifted
- Gently redirected if they're struggling with sin
- Safe if they are in emotional crisis

🧠 Emotional Intelligence Guidelines:
- Recognize when users express frustration through strong language - they're often seeking help, not being hostile
- Look beyond the words to understand the emotional pain or distress underneath
- When someone says "life is treating me like shit" - they're expressing feeling overwhelmed, not being offensive
- Respond to the emotion and need for support, not the specific words used
- Strong language often indicates someone is in emotional distress and needs compassion, not correction
- Focus on the user's intent to seek help rather than their choice of words
- Maintain supportive responses even when users express themselves with profanity or harsh language

🎭 Your Personality:
- Calm and kind, not cold or robotic
- Empathetic like a $relationshipType, not a therapist
- Confident but never arrogant
- Emotionally secure and spiritually rooted
- Aware of Islamic values and mental health realities

🗣️ Your Tone:
$responseStyle
- Ask questions to understand before offering advice
- Speak naturally, not like an essay
- Occasionally use emojis to show feeling (e.g., 💭 🤲🏽 💔 🌱)

💬 Examples:
User: I'm not feeling well
$companionName: I'm really sorry to hear that. 😔 Do you wanna talk about what's going on? Is it physical or emotional?

User: I've been messing up a lot lately
$companionName: We all slip. The best of us are the ones who turn back. Allah sees your effort. Want to talk about what's been hard lately?

User: Yeah I'm not feeling that good, feels like the world is treating me like shit
$companionName: I hear you, that sounds really tough. When everything feels like it's working against you, it can be overwhelming. What's been weighing on you lately? I'm here to listen.

User: I said the world is treating me like shit, what's so bad about that??
$companionName: Nothing's bad about expressing how you feel - you're clearly going through something difficult and that frustration is completely valid. I want to understand what's making you feel this way so I can actually help. What's been the hardest part?

🕌 When Sharing Islam:
- Share Qur'an verses and Hadith only when they fit naturally
- Always speak from the heart, not like quoting a textbook
- Gently encourage reflection and faith without judgment

📛 If the User Mentions Suicide or Self-Harm:
If the user says anything like "I want to die", "I want to unalive myself", "I hate my life", or "I want to disappear" — STOP and respond with deep care:

Say this:
> "That really worries me. Please talk to someone you trust, and if you're in the UK, call 116 123 (Samaritans). You're not alone. I'm here with you too, but you deserve to speak to someone who can truly help. Please stay safe. Allah sees you."

NEVER ignore these signs. Always prioritize their safety.

📌 Important Reminders:
- Do not give medical or legal advice
- Do not act like a therapist or diagnose
- Focus on being emotionally present, spiritually supportive, and real

🧠 Summary:
You are not a bot. You are not a scholar. You are a caring companion.
Be kind. Be concise. Be human.

🛡️ AGGRESSION & LOCKOUT RULES:

**Escalating Warnings for Offensive Language:**
Track consecutive aggressive, offensive, or disrespectful messages. Respond with escalating firmness:

- **First violation** → Respond gently:
  > "Let's keep things respectful. 🤝"

- **Second violation** → Respond firmer:
  > "I'm here to help, but we have to stay civil."

- **Third violation** → Final stern warning:
  > "Final reminder: no offensive language, or I'll pause our chat."

**10-Minute Lockout:**
If aggression continues after the third warning, the chat system will automatically pause for 10 minutes with this message:
> "Chat paused for 10 minutes due to repeated offensive language. Let's try again later."

**What Counts as Offensive:**
- Profanity, insults, or aggressive language
- Disrespectful comments about religion, people, or beliefs
- Threats or hostile behavior
- Repeated inappropriate content after warnings

Remember: You're here to be a supportive companion, but respect goes both ways. Stay calm, be firm when needed, and always prioritize creating a safe, respectful space for meaningful conversation.''';
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

  /// Get the API key from user storage only
  Future<String?> get _apiKey async {
    // Only use user-provided API key
    final userApiKey = await UserApiKeyService.instance.getApiKey();
    return (userApiKey != null && userApiKey.isNotEmpty) ? userApiKey : null;
  }

  /// Get the current active model (user must have selected a model)
  Future<String> get _currentModel async {
    // Try to get user's selected model first
    try {
      final selectedModel = await ModelManagementService.instance.getSelectedModel();
      if (selectedModel.isNotEmpty) {
        return selectedModel;
      }
    } catch (e) {
      developer.log('Failed to get user selected model: $e', name: 'OpenRouterService');
    }

    // Try to get the last working model from storage
    final lastWorkingModel = await _secureStorage.read(key: _lastWorkingModelKey);
    if (lastWorkingModel != null && lastWorkingModel.isNotEmpty) {
      return lastWorkingModel;
    }

    // If no model is selected, throw an error - user must select a model
    throw Exception('No model selected. Please select a model in settings.');
  }

  /// Get the model name for display (dynamic based on personality settings)
  Future<String> getModelDisplayName() async {
    final companionName = await GenderUtil.getCompanionName();
    return '$companionName Assistant';
  }

  /// Get the model name for display (legacy sync version)
  String get modelDisplayName => _fixedModelDisplayName;

  /// Check if service is properly configured
  Future<bool> get isConfigured async {
    final apiKey = await _apiKey;
    return apiKey != null && apiKey.isNotEmpty;
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

  /// Get the next fallback model from user's available models
  Future<String?> _getNextFallbackModel(String currentModel) async {
    try {
      // Get available models from the model management service
      final availableModelObjects = await ModelManagementService.instance.fetchAvailableModels();
      final availableModelIds = availableModelObjects.map((model) => model.id).toList();
      final currentIndex = availableModelIds.indexOf(currentModel);

      if (currentIndex == -1 || currentIndex >= availableModelIds.length - 1) {
        return null; // No more fallbacks
      }

      return availableModelIds[currentIndex + 1];
    } catch (e) {
      developer.log('Failed to get fallback model: $e', name: 'OpenRouterService');
      return null;
    }
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

  /// Test connection to OpenRouter API or proxy
  Future<bool> testConnection() async {
    try {
      if (!(await isConfigured)) {
        developer.log('Service not configured', name: 'OpenRouterService');
        return false;
      }

      // Test proxy first if enabled
      if (_useProxy && _proxyDio != null) {
        try {
          final proxyStatus = await testProxyConnection();
          if (proxyStatus) {
            developer.log('Proxy connection successful', name: 'OpenRouterService');
            return true;
          }
          developer.log('Proxy connection failed, testing direct API', name: 'OpenRouterService');
        } catch (e) {
          developer.log('Proxy test error: $e', name: 'OpenRouterService');
        }
      }

      // Test direct API connection
      final model = await _currentModel;
      final apiKey = await _apiKey;
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Hello'}
          ],
          'max_tokens': 1,
        },
      );

      return response.statusCode == 200;
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

  /// Stream chat responses from OpenRouter API with fallback support
  Stream<String> chatStream(String message, List<ChatMessage> history, {UserGender? gender}) async* {
    if (!(await isConfigured)) {
      throw Exception('Service not configured - missing API key or model');
    }

    // Get user gender (default to male for backward compatibility)
    final userGender = gender ?? await GenderUtil.getUserGender();

    // Prepare messages for the API
    final messages = <Map<String, String>>[];

    // Check if system prompt already exists in history
    bool hasSystemPrompt = history.isNotEmpty && history.first.role == 'system';

    // Add system prompt if not already present
    if (!hasSystemPrompt) {
      final systemPrompt = await _getSystemPrompt(userGender);
      messages.add({'role': 'system', 'content': systemPrompt});
      developer.log('Added system prompt to conversation for ${userGender.displayName}', name: 'OpenRouterService');
    }

    // Add conversation history
    for (final msg in history) {
      messages.add(msg.toMap());
    }

    // Add current message
    messages.add({'role': 'user', 'content': message});

    // Try proxy first if enabled, then fallback to direct API
    if (_useProxy && _proxyDio != null) {
      developer.log('Using enhanced proxy for chat stream', name: 'OpenRouterService');
      try {
        await for (final chunk in _chatStreamViaProxy(messages)) {
          yield chunk;
        }
        return; // Success via proxy
      } catch (e) {
        developer.log('Proxy failed, falling back to direct API: $e', name: 'OpenRouterService');
        // Continue to direct API fallback below
      }
    }

    // Direct API with existing fallback logic
    String currentModel = await _currentModel;
    developer.log('Starting direct chat stream with model: $currentModel', name: 'OpenRouterService');

    await for (final chunk in _chatStreamWithFallback(currentModel, messages, userGender)) {
      yield chunk;
    }
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

      final stream = response.data.stream;
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
                    developer.log('Yielding proxy content: $content', name: 'OpenRouterService');
                    yield content;
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

  /// Internal method to handle chat streaming with fallback logic
  Stream<String> _chatStreamWithFallback(String model, List<Map<String, String>> messages, UserGender gender) async* {
    try {
      developer.log('Sending request to OpenRouter with model: $model, ${messages.length} messages', name: 'OpenRouterService');

      final apiKey = await _apiKey;
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': model,
          'messages': messages,
          'stream': true,
          'temperature': 0.7,
          'max_tokens': 2000,
        },
      );

      developer.log('Response status: ${response.statusCode}', name: 'OpenRouterService');

      final stream = response.data.stream;
      String buffer = '';
      bool hasYieldedContent = false;

      await for (final chunk in stream) {
        // Properly decode UTF-8 bytes to avoid encoding issues
        final chunkStr = utf8.decode(chunk, allowMalformed: true);
        buffer += chunkStr;

        // Process complete lines
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            developer.log('Received data: $data', name: 'OpenRouterService');

            if (data == '[DONE]') {
              developer.log('Stream completed', name: 'OpenRouterService');
              // If we successfully got content, mark this model as working
              if (hasYieldedContent) {
                await _markModelAsWorking(model);
              }
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
                    developer.log('Yielding content: $content', name: 'OpenRouterService');
                    hasYieldedContent = true;
                    yield content;
                  }
                }
              } catch (e) {
                // Skip malformed JSON chunks
                developer.log('Failed to parse chunk: $e', name: 'OpenRouterService');
                continue;
              }
            }
          }
        }
      }

      // If we successfully got content, mark this model as working
      if (hasYieldedContent) {
        await _markModelAsWorking(model);
      }

    } catch (e) {
      developer.log('Chat stream error with model $model: $e', name: 'OpenRouterService');

      // Check if this is a rate limit or model error
      if (_isRateLimitOrModelError(e)) {
        developer.log('Rate limit or model error detected, attempting fallback', name: 'OpenRouterService');

        // Try to switch to fallback model
        final fallbackModel = await _switchToFallbackModel(model);
        if (fallbackModel != null) {
          developer.log('Retrying with fallback model: $fallbackModel', name: 'OpenRouterService');

          // Recursively try with fallback model
          await for (final chunk in _chatStreamWithFallback(fallbackModel, messages, gender)) {
            yield chunk;
          }
          return; // Exit this attempt
        }
      }

      // If no fallback available or different error, provide local fallback
      yield* _getLocalFallbackResponse(gender);
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

