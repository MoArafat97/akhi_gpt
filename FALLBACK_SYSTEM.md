# Akhi GPT - Robust Fallback System

## Overview

The Akhi GPT app now includes a comprehensive fallback system that handles OpenRouter API rate limits and model unavailability seamlessly. Users experience uninterrupted conversations while the system automatically switches between models behind the scenes.

## Key Features

### ✅ **Invisible to Users**
- No technical error messages shown to users
- Seamless conversation flow maintained
- Consistent Akhi personality across all models

### ✅ **Smart Model Switching**
- Automatic detection of rate limits and model errors
- Hierarchical fallback through multiple models
- Persistent tracking of last working model

### ✅ **Graceful Degradation**
- Local fallback message when all models fail
- Crisis intervention information included
- Maintains supportive tone even in fallback

## Model Hierarchy

The system uses a prioritized list of free models:

1. **Primary**: `deepseek/deepseek-r1-0528-qwen3-8b:free`
2. **Fallback 1**: `qwen/qwen-2.5-72b-instruct:free`
3. **Fallback 2**: `qwen/qwen-2.5-32b-instruct:free`
4. **Last Resort**: Local supportive message with crisis resources

## Technical Implementation

### Error Detection

The system detects the following error conditions:
- HTTP 429 (Rate Limit Exceeded)
- HTTP 503 (Service Unavailable)
- HTTP 502 (Bad Gateway)
- OpenRouter-specific error messages containing:
  - "rate limit"
  - "quota"
  - "unavailable"

### Model Persistence

Uses `flutter_secure_storage` to remember:
- Last working model
- Model failure counts
- Automatic reset on successful responses

### Fallback Flow

```
User Message → Primary Model
     ↓ (if rate limited)
Fallback Model 1
     ↓ (if rate limited)
Fallback Model 2
     ↓ (if all fail)
Local Fallback Message
```

## Code Structure

### OpenRouterService Changes

- **New Methods**:
  - `_isRateLimitOrModelError()` - Detects API errors
  - `_getNextFallbackModel()` - Gets next model in hierarchy
  - `_markModelAsWorking()` - Persists successful model
  - `_switchToFallbackModel()` - Switches to next fallback
  - `_chatStreamWithFallback()` - Handles recursive fallback
  - `_getLocalFallbackResponse()` - Provides local fallback

- **Enhanced Properties**:
  - `_currentModel` - Async getter for active model
  - `_fallbackModels` - Static list of fallback models
  - Secure storage integration

### ConfigHelper Enhancements

- **New Methods**:
  - `getStatus()` - Async status with fallback info
  - `resetToDefaultModel()` - Reset fallback state
  - `getFallbackModels()` - Get available models

- **Backward Compatibility**:
  - `getStatusSync()` - Maintains existing API

### ChatScreen Updates

- **Improved Error Handling**:
  - Removes technical error messages
  - Provides user-friendly fallback
  - Maintains conversation flow

## Usage Examples

### Basic Chat (Transparent to User)
```dart
// User sends message - system handles fallbacks automatically
final stream = openRouterService.chatStream("Hello", history);
await for (final chunk in stream) {
  // User sees response regardless of which model provided it
  print(chunk);
}
```

### Status Checking
```dart
// Check current system status
final status = await ConfigHelper.getStatus();
print('Last working model: ${status['lastWorkingModel']}');
print('Has fallback support: ${status['hasFallbackSupport']}');
```

### Reset Fallback State
```dart
// Reset to primary model (useful for testing)
await ConfigHelper.resetToDefaultModel();
```

## Local Fallback Message

When all models are unavailable, users receive:

```
Hey akhi, I'm having some technical difficulties right now, but I'm still here for you. 🤲

While I sort this out, remember that Allah (SWT) is always with you, even in the hardest moments. Take a deep breath, make du'a, and know that this too shall pass.

If you're in crisis or need immediate help, please reach out to:
🇬🇧 UK: Samaritans - 116 123 (free, 24/7)
🌍 Or your local emergency services

I'll be back to full capacity soon, insha'Allah. Stay strong, brother. 💙
```

## Testing

Run the fallback system tests:
```bash
flutter test test/fallback_service_test.dart
```

## Benefits

1. **User Experience**: Seamless conversations without technical interruptions
2. **Reliability**: Multiple fallback options ensure service availability
3. **Cost Efficiency**: Automatic switching to available free models
4. **Mental Health Focus**: Crisis support even in fallback scenarios
5. **Developer Friendly**: Comprehensive logging and status reporting

## Future Enhancements

- Dynamic model discovery from OpenRouter API
- Usage analytics and model performance tracking
- Configurable fallback delays and retry logic
- A/B testing different fallback strategies
