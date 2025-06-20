# Enhanced OpenRouter Proxy System

## Overview

The Enhanced OpenRouter Proxy System is a sophisticated backend solution that provides intelligent fallbacks, rate limiting, and caching optimizations for the Akhi GPT chat application. This system acts as an intermediary between the Flutter client and OpenRouter API, ensuring reliable and scalable chat functionality.

## 🏗️ Architecture

```
Flutter App → Enhanced Proxy → OpenRouter API
     ↓              ↓              ↓
Direct Fallback → Local Cache → Multiple Models
```

### Components

1. **Enhanced Google Cloud Function** (`index.js`)
   - Intelligent proxy with fallback logic
   - Rate limiting and request throttling
   - Response caching and deduplication
   - Health monitoring and status reporting

2. **Flutter OpenRouter Service** (`lib/services/openrouter_service.dart`)
   - Proxy-aware client with dual-mode operation
   - Automatic fallback to direct API when proxy fails
   - Maintains existing fallback logic as secondary layer

3. **Configuration Management** (`.env`)
   - Comprehensive environment variable configuration
   - Support for multiple fallback models
   - Configurable rate limiting and caching parameters

## 🚀 Key Features

### Intelligent Fallback System
- **Multi-Model Support**: Configurable list of fallback models
- **Error Detection**: Smart detection of rate limits and model failures
- **Model Health Tracking**: Persistent tracking of working/failed models
- **Graceful Degradation**: Local fallback messages with crisis support

### Rate Limiting & Optimization
- **Request Throttling**: Configurable rate limits with burst capacity
- **Prompt Deduplication**: Prevents duplicate requests within time windows
- **Response Caching**: Intelligent caching of recent responses
- **Request Queueing**: Manages concurrent requests efficiently

### Monitoring & Analytics
- **Health Status Endpoint**: Real-time proxy and model status
- **Cache Statistics**: Hit/miss ratios and performance metrics
- **Rate Limiter Metrics**: Queue depth and throughput monitoring

## 🔧 Configuration

### Environment Variables

#### Required
```env
OPENROUTER_API_KEY=your-api-key-here
DEFAULT_MODEL=deepseek/deepseek-r1-0528-qwen3-8b:free
FALLBACK_MODELS=deepseek/deepseek-r1-0528-qwen3-8b:free,qwen/qwen-2.5-72b-instruct:free,qwen/qwen-2.5-32b-instruct:free
```

#### Proxy Configuration
```env
PROXY_ENDPOINT=http://localhost:8080
ENABLE_PROXY=false
```

#### Rate Limiting
```env
RATE_LIMIT_REQUESTS_PER_MINUTE=30
RATE_LIMIT_BURST_SIZE=5
THROTTLE_DELAY_MS=1000
```

#### Caching
```env
CACHE_TTL_SECONDS=300
CACHE_MAX_ENTRIES=1000
ENABLE_PROMPT_DEDUPLICATION=true
DEDUPLICATION_WINDOW_MS=5000
```

#### Request Optimization
```env
ENABLE_REQUEST_QUEUEING=true
MAX_CONCURRENT_REQUESTS=3
REQUEST_TIMEOUT_MS=30000
```

## 🛠️ Deployment

### Local Development
```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Start the proxy
npm start

# Test the proxy
node test-proxy.js
```

### Google Cloud Functions
```bash
# Deploy with enhanced configuration
./deploy.sh "your-api-key" "deepseek/deepseek-r1-0528-qwen3-8b:free"

# Or deploy with custom fallback models
./deploy.sh "your-api-key" "primary-model" "model1,model2,model3"
```

## 📊 API Endpoints

### Chat Endpoint
**POST** `/`
```json
{
  "history": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Previous message"}
  ],
  "prompt": "Current user message"
}
```

**Response**: Server-Sent Events stream
```
data: {"choices":[{"delta":{"content":"Hello"}}]}

data: {"choices":[{"delta":{"content":" there!"}}]}

data: [DONE]
```

### Status Endpoint
**GET** `/status`

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-20T10:30:00.000Z",
  "configuration": {
    "fallbackModels": ["model1", "model2", "model3"],
    "rateLimitEnabled": true,
    "cachingEnabled": true,
    "queueingEnabled": true
  },
  "modelStatuses": {
    "model1": {"status": "working", "lastSuccess": 1642680600000},
    "model2": {"status": "failed", "lastFailure": 1642680500000}
  },
  "cacheStats": {
    "responseCache": {"keys": 150, "hits": 89, "misses": 61},
    "deduplicationCache": {"keys": 25}
  },
  "rateLimiter": {
    "running": 2,
    "queued": 0
  }
}
```

## 🧪 Testing

### Flutter Tests
```bash
flutter test test/enhanced_proxy_test.dart
```

### Node.js Tests
```bash
node test-proxy.js
```

### Integration Testing
1. Start the proxy locally: `npm start`
2. Enable proxy in Flutter: Set `ENABLE_PROXY=true` in `.env`
3. Run Flutter app and test chat functionality
4. Monitor proxy status at `http://localhost:8080/status`

## 🔍 Monitoring

### Health Checks
- **Proxy Status**: `GET /status` endpoint
- **Model Health**: Tracked automatically with failure counts
- **Cache Performance**: Hit/miss ratios in status response
- **Rate Limiting**: Queue depth and throughput metrics

### Logging
- **Request Logging**: All requests logged with model and status
- **Error Logging**: Detailed error information for debugging
- **Performance Logging**: Response times and cache statistics

## 🚨 Error Handling

### Fallback Hierarchy
1. **Primary Model**: Configured default model
2. **Fallback Models**: Secondary models in priority order
3. **Local Fallback**: Crisis-aware supportive message

### Error Types
- **Rate Limiting**: HTTP 429, quota exceeded messages
- **Model Unavailability**: HTTP 503, service unavailable
- **Network Errors**: Connection timeouts, DNS failures
- **API Errors**: Invalid responses, authentication failures

## 🔒 Security

### API Key Management
- Environment variable configuration
- No hardcoded credentials
- Secure storage in Google Cloud Functions

### Request Validation
- Input sanitization and validation
- CORS configuration for cross-origin requests
- Rate limiting to prevent abuse

## 📈 Performance Optimizations

### Caching Strategy
- **Response Caching**: Recent responses cached for quick retrieval
- **Prompt Deduplication**: Prevents duplicate processing
- **Model Status Caching**: Reduces unnecessary API calls

### Rate Limiting
- **Burst Handling**: Allows short bursts while maintaining limits
- **Queue Management**: Intelligent request queuing
- **Throttling**: Configurable delays between requests

## 🔄 Migration Guide

### From Direct API to Proxy
1. Deploy the enhanced proxy to Google Cloud Functions
2. Update `.env` to include `PROXY_ENDPOINT` and set `ENABLE_PROXY=true`
3. Test proxy functionality with status endpoint
4. Monitor chat functionality for seamless operation

### Rollback Strategy
1. Set `ENABLE_PROXY=false` in Flutter app configuration
2. App automatically falls back to direct OpenRouter API
3. Existing fallback logic continues to work as before

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Install dependencies: `npm install`
3. Configure environment variables
4. Run tests: `npm test` and `flutter test`
5. Submit pull request with comprehensive tests

### Code Standards
- ESLint configuration for JavaScript
- Dart analysis for Flutter code
- Comprehensive test coverage
- Documentation for new features
