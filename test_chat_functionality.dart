import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 Testing Akhi GPT Chat Functionality...');
  
  // Read .env file manually
  String? apiKey;
  String? defaultModel;
  List<String> fallbackModels = [];
  
  try {
    final envFile = File('.env');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      for (final line in lines) {
        if (line.startsWith('OPENROUTER_API_KEY=')) {
          apiKey = line.substring('OPENROUTER_API_KEY='.length);
        } else if (line.startsWith('DEFAULT_MODEL=')) {
          defaultModel = line.substring('DEFAULT_MODEL='.length);
        } else if (line.startsWith('FALLBACK_MODELS=')) {
          final fallbackString = line.substring('FALLBACK_MODELS='.length);
          fallbackModels = fallbackString.split(',').map((e) => e.trim()).toList();
        }
      }
      print('✅ .env file loaded successfully');
    } else {
      print('❌ .env file not found');
      return;
    }
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    return;
  }
  
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ OPENROUTER_API_KEY not found in .env file');
    return;
  }
  
  print('✅ API Key found: ${apiKey.substring(0, 20)}...');
  print('✅ Default Model: $defaultModel');
  print('✅ Fallback Models: $fallbackModels');
  
  // Test each model
  final modelsToTest = [defaultModel, ...fallbackModels];
  
  for (final model in modelsToTest) {
    if (model == null || model.isEmpty) continue;
    
    print('\n🔍 Testing model: $model');
    
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/MoArafat97/akhi_gpt',
          'X-Title': 'Akhi GPT',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI assistant. Respond briefly and naturally.'
            },
            {
              'role': 'user',
              'content': 'Hello, please respond with "Model $model is working correctly".'
            }
          ],
          'max_tokens': 50,
          'temperature': 0.7,
        }),
      );
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('✅ Model $model: SUCCESS');
        print('📝 Response: $content');
        break; // Found working model, stop testing
      } else {
        print('❌ Model $model: FAILED (${response.statusCode})');
        print('📝 Error: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Model $model: EXCEPTION - $e');
    }
  }
  
  print('\n🔍 Test completed.');
}
