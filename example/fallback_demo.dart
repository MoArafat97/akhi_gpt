// Example demonstrating the Akhi GPT fallback system
// This file shows how the fallback system works in practice

import 'dart:developer' as developer;
import '../lib/services/openrouter_service.dart';
import '../lib/utils/config_helper.dart';
import '../lib/models/chat_message.dart';

/// Demo class showing fallback system usage
class FallbackDemo {
  static final OpenRouterService _service = OpenRouterService();

  /// Demonstrate normal chat flow with automatic fallbacks
  static Future<void> demonstrateChat() async {
    print('🤖 Akhi GPT Fallback System Demo\n');

    // Check system status
    final status = await ConfigHelper.getStatus();
    print('📊 System Status:');
    print('   Configured: ${status['isConfigured']}');
    print('   Current Model: ${status['currentModel']}');
    print('   Last Working: ${status['lastWorkingModel'] ?? 'None'}');
    print('   Fallback Support: ${status['hasFallbackSupport']}\n');

    // Show available fallback models
    final fallbackModels = ConfigHelper.getFallbackModels();
    print('🔄 Available Fallback Models:');
    for (int i = 0; i < fallbackModels.length; i++) {
      print('   ${i + 1}. ${fallbackModels[i]}');
    }
    print('   ${fallbackModels.length + 1}. Local Fallback Message\n');

    // Simulate a chat conversation
    print('💬 Starting Chat Simulation...\n');
    
    final history = <ChatMessage>[];
    final testMessage = "Assalamu alaikum, I'm feeling anxious today";

    try {
      print('User: $testMessage');
      print('Akhi: ');

      // The service will automatically handle fallbacks if needed
      final stream = _service.chatStream(testMessage, history);
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
      }

      print(buffer.toString());
      
      print('\n\n✅ Chat completed successfully!');
      
      // Show updated status
      final updatedStatus = await ConfigHelper.getStatus();
      if (updatedStatus['lastWorkingModel'] != null) {
        print('🎯 Last working model: ${updatedStatus['lastWorkingModel']}');
      }

    } catch (e) {
      print('\n❌ Chat failed: $e');
    }
  }

  /// Demonstrate status checking and model management
  static Future<void> demonstrateStatusManagement() async {
    print('\n🔧 Status Management Demo\n');

    // Get detailed status
    final status = await ConfigHelper.getStatus();
    print('📋 Detailed Status:');
    status.forEach((key, value) {
      print('   $key: $value');
    });

    // Test connection
    print('\n🔌 Testing Connection...');
    final connectionOk = await ConfigHelper.testConnection();
    print('   Connection Status: ${connectionOk ? "✅ OK" : "❌ Failed"}');

    // Reset fallback state (for testing)
    print('\n🔄 Resetting Fallback State...');
    await ConfigHelper.resetToDefaultModel();
    print('   ✅ Reset complete');

    // Check status after reset
    final resetStatus = await ConfigHelper.getStatus();
    print('   Last Working Model: ${resetStatus['lastWorkingModel'] ?? 'None (reset)'}');
  }

  /// Simulate error scenarios (for testing purposes)
  static void demonstrateErrorScenarios() {
    print('\n⚠️  Error Scenario Simulation\n');

    print('🔍 The system detects these error conditions:');
    print('   • HTTP 429 (Rate Limit Exceeded)');
    print('   • HTTP 503 (Service Unavailable)');
    print('   • HTTP 502 (Bad Gateway)');
    print('   • OpenRouter error messages containing:');
    print('     - "rate limit"');
    print('     - "quota"');
    print('     - "unavailable"');

    print('\n🔄 Fallback Flow:');
    print('   1. Primary Model (deepseek-r1-0528-qwen3-8b:free)');
    print('   2. ↓ Rate Limited');
    print('   3. Fallback 1 (qwen-2.5-72b-instruct:free)');
    print('   4. ↓ Rate Limited');
    print('   5. Fallback 2 (qwen-2.5-32b-instruct:free)');
    print('   6. ↓ All Models Failed');
    print('   7. Local Fallback Message with Crisis Support');

    print('\n💙 Local Fallback Message Preview:');
    print('   "Hey akhi, I\'m having some technical difficulties...');
    print('   ...includes crisis intervention resources');
    print('   ...maintains supportive Akhi personality"');
  }

  /// Show the benefits of the fallback system
  static void showBenefits() {
    print('\n🌟 Fallback System Benefits\n');

    final benefits = [
      '👤 User Experience: Seamless conversations without interruptions',
      '🔒 Reliability: Multiple fallback options ensure availability',
      '💰 Cost Efficiency: Automatic switching to available free models',
      '🧠 Mental Health Focus: Crisis support even in fallback scenarios',
      '🛠️  Developer Friendly: Comprehensive logging and status reporting',
      '🔄 Smart Recovery: Remembers last working model for faster recovery',
      '🎯 Invisible Operation: Users never see technical error messages',
    ];

    benefits.forEach(print);
  }
}

/// Main demo function
Future<void> main() async {
  try {
    // Run all demonstrations
    await FallbackDemo.demonstrateChat();
    await FallbackDemo.demonstrateStatusManagement();
    FallbackDemo.demonstrateErrorScenarios();
    FallbackDemo.showBenefits();

    print('\n🎉 Demo completed successfully!');
    print('💡 The fallback system is now ready for production use.');

  } catch (e) {
    developer.log('Demo error: $e', name: 'FallbackDemo');
    print('\n❌ Demo failed: $e');
    print('💡 Make sure your .env file is configured with a valid API key.');
  }
}
