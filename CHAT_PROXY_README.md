# Enhanced Chat Proxy Google Cloud Function

A sophisticated Google Cloud Function that acts as an intelligent proxy for OpenRouter's chat completions API, featuring advanced fallback mechanisms, rate limiting, and caching optimizations.

## 🚀 Enhanced Features

### Core Functionality
- ✅ HTTP POST endpoint at `/chat` with streaming support
- ✅ HTTP GET endpoint at `/status` for health monitoring
- ✅ Server-Sent Events streaming from OpenRouter API
- ✅ CORS support for cross-origin requests
- ✅ Comprehensive error handling and validation

### 🧠 Intelligent Fallback System
- ✅ **Multi-Model Fallback**: Automatic switching between multiple models
- ✅ **Rate Limit Detection**: Smart detection of 429, 503, and quota errors
- ✅ **Model Health Tracking**: Persistent tracking of working/failed models
- ✅ **Graceful Degradation**: Local fallback messages when all models fail

### ⚡ Rate Limiting & Optimization
- ✅ **Request Throttling**: Configurable rate limiting with burst support
- ✅ **Prompt Deduplication**: Prevents duplicate requests within time windows
- ✅ **Response Caching**: Intelligent caching of recent responses
- ✅ **Request Queueing**: Manages concurrent requests efficiently

### 📊 Monitoring & Analytics
- ✅ **Health Status Endpoint**: Real-time proxy and model status
- ✅ **Cache Statistics**: Hit/miss ratios and performance metrics
- ✅ **Rate Limiter Metrics**: Queue depth and throughput monitoring

## Prerequisites

- Google Cloud SDK installed and configured
- Node.js 18+ for local development
- OpenRouter API key

## 🔧 Environment Variables

### Required Configuration
- `OPENROUTER_API_KEY`: Your OpenRouter API key
- `DEFAULT_MODEL`: Primary model (e.g., "deepseek/deepseek-r1-0528-qwen3-8b:free")
- `FALLBACK_MODELS`: Comma-separated list of fallback models

### Rate Limiting Configuration
- `RATE_LIMIT_REQUESTS_PER_MINUTE`: Max requests per minute (default: 30)
- `RATE_LIMIT_BURST_SIZE`: Burst capacity (default: 5)
- `THROTTLE_DELAY_MS`: Minimum delay between requests (default: 1000)

### Caching Configuration
- `CACHE_TTL_SECONDS`: Response cache TTL (default: 300)
- `CACHE_MAX_ENTRIES`: Maximum cached responses (default: 1000)
- `ENABLE_PROMPT_DEDUPLICATION`: Enable duplicate detection (default: true)
- `DEDUPLICATION_WINDOW_MS`: Deduplication time window (default: 5000)

### Request Optimization
- `ENABLE_REQUEST_QUEUEING`: Enable request queueing (default: true)
- `MAX_CONCURRENT_REQUESTS`: Max concurrent requests (default: 3)
- `REQUEST_TIMEOUT_MS`: Request timeout (default: 30000)

## 🛠️ Local Development

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables in `.env`:
```env
# Required
OPENROUTER_API_KEY=your-api-key-here
DEFAULT_MODEL=deepseek/deepseek-r1-0528-qwen3-8b:free
FALLBACK_MODELS=deepseek/deepseek-r1-0528-qwen3-8b:free,qwen/qwen-2.5-72b-instruct:free

# Optional (with defaults)
RATE_LIMIT_REQUESTS_PER_MINUTE=30
CACHE_TTL_SECONDS=300
ENABLE_PROMPT_DEDUPLICATION=true
```

3. Start the function locally:
```bash
npm start
```

4. Test the enhanced proxy:
```bash
node test-proxy.js
```

The function will be available at:
- Chat endpoint: `http://localhost:8080`
- Status endpoint: `http://localhost:8080/status`

## Deployment

1. Deploy to Google Cloud Functions:
```bash
gcloud functions deploy chatProxy \
  --runtime nodejs18 \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars OPENROUTER_API_KEY="your-api-key",DEFAULT_MODEL="deepseek-r1"
```

2. Or use the npm script:
```bash
npm run deploy
```

## API Usage

### Request

**Endpoint:** `POST /chat`

**Headers:**
- `Content-Type: application/json`

**Body:**
```json
{
  "history": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"},
    {"role": "assistant", "content": "Hi there! How can I help you?"}
  ],
  "prompt": "What's the weather like?"
}
```

### Response

The function returns Server-Sent Events with the following format:

```
data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"deepseek-r1","choices":[{"delta":{"content":"Hello"},"index":0,"finish_reason":null}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"deepseek-r1","choices":[{"delta":{"content":" there"},"index":0,"finish_reason":null}]}

data: [DONE]
```

## Error Handling

The function handles various error scenarios:

- Invalid HTTP methods (returns 405)
- Missing or invalid request body (returns 400)
- Missing environment variables (returns 500)
- OpenRouter API errors (forwards the error status)
- Stream processing errors (returns 500)

## CORS Support

The function includes CORS headers to allow cross-origin requests from web applications.

## License

MIT
