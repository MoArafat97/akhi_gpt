const { functionsFramework } = require('@google-cloud/functions-framework');
const fetch = require('node-fetch').default;
const { createParser } = require('eventsource-parser');
const NodeCache = require('node-cache');
const Bottleneck = require('bottleneck');
const { v4: uuidv4 } = require('uuid');

// Load environment variables from .env file for local development
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

// Initialize caching and rate limiting
const responseCache = new NodeCache({
  stdTTL: parseInt(process.env.CACHE_TTL_SECONDS) || 300,
  maxKeys: parseInt(process.env.CACHE_MAX_ENTRIES) || 1000
});

const promptDeduplicationCache = new NodeCache({
  stdTTL: (parseInt(process.env.DEDUPLICATION_WINDOW_MS) || 5000) / 1000,
  maxKeys: 500
});

// Rate limiter configuration
const limiter = new Bottleneck({
  maxConcurrent: parseInt(process.env.MAX_CONCURRENT_REQUESTS) || 3,
  minTime: parseInt(process.env.THROTTLE_DELAY_MS) || 1000,
  reservoir: parseInt(process.env.RATE_LIMIT_BURST_SIZE) || 5,
  reservoirRefreshAmount: parseInt(process.env.RATE_LIMIT_REQUESTS_PER_MINUTE) || 30,
  reservoirRefreshInterval: 60 * 1000 // 1 minute
});

// Fallback models configuration
const getFallbackModels = () => {
  const fallbackModelsStr = process.env.FALLBACK_MODELS || process.env.DEFAULT_MODEL;
  return fallbackModelsStr ? fallbackModelsStr.split(',').map(m => m.trim()) : [];
};

// Model persistence for tracking working models
const modelStatus = new Map();

/**
 * Utility Functions
 */

// Generate cache key for requests
function generateCacheKey(model, messages) {
  const messageHash = JSON.stringify(messages.slice(-3)); // Last 3 messages for context
  return `${model}:${Buffer.from(messageHash).toString('base64').slice(0, 32)}`;
}

// Generate deduplication key for prompts
function generateDeduplicationKey(prompt, userId = 'anonymous') {
  return `${userId}:${Buffer.from(prompt).toString('base64').slice(0, 32)}`;
}

// Check if error indicates rate limiting or model unavailability
function isRateLimitOrModelError(error, responseText) {
  if (!error && !responseText) return false;

  // Check HTTP status codes
  if (error && error.status) {
    if (error.status === 429) return true; // Rate limit
    if (error.status === 503) return true; // Service unavailable
    if (error.status === 502) return true; // Bad gateway
  }

  // Check OpenRouter specific error messages
  if (responseText) {
    const lowerText = responseText.toLowerCase();
    return lowerText.includes('rate limit') ||
           lowerText.includes('quota') ||
           lowerText.includes('unavailable') ||
           lowerText.includes('rate_limit') ||
           lowerText.includes('quota_exceeded');
  }

  return false;
}

// Get next fallback model
function getNextFallbackModel(currentModel) {
  const models = getFallbackModels();
  const currentIndex = models.indexOf(currentModel);

  if (currentIndex === -1 || currentIndex >= models.length - 1) {
    return null; // No more fallbacks
  }

  return models[currentIndex + 1];
}

// Mark model as working
function markModelAsWorking(model) {
  modelStatus.set(model, {
    status: 'working',
    lastSuccess: Date.now(),
    failureCount: 0
  });
  console.log(`Marked model as working: ${model}`);
}

// Mark model as failed
function markModelAsFailed(model) {
  const current = modelStatus.get(model) || { failureCount: 0 };
  modelStatus.set(model, {
    status: 'failed',
    lastFailure: Date.now(),
    failureCount: current.failureCount + 1
  });
  console.log(`Marked model as failed: ${model} (failures: ${current.failureCount + 1})`);
}

// Get best available model
function getBestAvailableModel() {
  const models = getFallbackModels();

  // Find the first model that's not marked as failed recently
  for (const model of models) {
    const status = modelStatus.get(model);
    if (!status || status.status === 'working') {
      return model;
    }

    // Reset failed status after 5 minutes
    if (status.status === 'failed' && Date.now() - status.lastFailure > 5 * 60 * 1000) {
      modelStatus.delete(model);
      return model;
    }
  }

  // If all models are marked as failed, return the primary model
  return models[0] || process.env.DEFAULT_MODEL;
}

/**
 * Enhanced streaming function with fallback support
 */
async function streamChatWithFallback(model, messages, res, attempt = 1) {
  const maxAttempts = getFallbackModels().length;

  try {
    console.log(`Attempt ${attempt}/${maxAttempts}: Trying model ${model}`);

    // Check for cached response first
    if (process.env.ENABLE_PROMPT_DEDUPLICATION === 'true') {
      const cacheKey = generateCacheKey(model, messages);
      const cachedResponse = responseCache.get(cacheKey);

      if (cachedResponse) {
        console.log('Returning cached response');
        res.write(`data: ${JSON.stringify({ choices: [{ delta: { content: cachedResponse } }] })}\n\n`);
        res.write('data: [DONE]\n\n');
        return true;
      }
    }

    // Make request to OpenRouter API with rate limiting
    const openRouterResponse = await limiter.schedule(() =>
      fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://akhi-gpt.app',
          'X-Title': 'Akhi GPT Enhanced Proxy'
        },
        body: JSON.stringify({
          model: model,
          messages: messages,
          stream: true,
          temperature: 0.7,
          max_tokens: 2000
        })
      })
    );

    if (!openRouterResponse.ok) {
      const errorText = await openRouterResponse.text();
      console.error(`Model ${model} failed:`, openRouterResponse.status, errorText);

      // Check if this is a rate limit or model error
      if (isRateLimitOrModelError({ status: openRouterResponse.status }, errorText)) {
        markModelAsFailed(model);

        // Try fallback model
        const fallbackModel = getNextFallbackModel(model);
        if (fallbackModel && attempt < maxAttempts) {
          console.log(`Falling back to model: ${fallbackModel}`);
          return await streamChatWithFallback(fallbackModel, messages, res, attempt + 1);
        }
      }

      throw new Error(`API Error: ${openRouterResponse.status} - ${errorText}`);
    }

    // Process streaming response
    const parser = createParser((event) => {
      if (event.type === 'event') {
        res.write(`data: ${event.data}\n\n`);

        if (event.data === '[DONE]') {
          markModelAsWorking(model);
          return;
        }

        // Cache successful content for deduplication
        if (process.env.ENABLE_PROMPT_DEDUPLICATION === 'true' && event.data !== '[DONE]') {
          try {
            const parsed = JSON.parse(event.data);
            const content = parsed.choices?.[0]?.delta?.content;
            if (content) {
              const cacheKey = generateCacheKey(model, messages);
              const existing = responseCache.get(cacheKey) || '';
              responseCache.set(cacheKey, existing + content);
            }
          } catch (e) {
            // Ignore parsing errors for caching
          }
        }
      }
    });

    const reader = openRouterResponse.body;

    reader.on('data', (chunk) => {
      const text = chunk.toString();
      parser.feed(text);
    });

    return new Promise((resolve, reject) => {
      reader.on('end', () => {
        markModelAsWorking(model);
        resolve(true);
      });

      reader.on('error', (error) => {
        console.error(`Stream error with model ${model}:`, error);
        markModelAsFailed(model);
        reject(error);
      });
    });

  } catch (error) {
    console.error(`Error with model ${model}:`, error);
    markModelAsFailed(model);

    // Try fallback model
    const fallbackModel = getNextFallbackModel(model);
    if (fallbackModel && attempt < maxAttempts) {
      console.log(`Falling back to model: ${fallbackModel}`);
      return await streamChatWithFallback(fallbackModel, messages, res, attempt + 1);
    }

    // If all models failed, provide local fallback
    console.log('All models failed, providing local fallback');
    const fallbackMessage = `Hey akhi, I'm having some technical difficulties right now, but I'm still here for you. 🤲

While I sort this out, remember that Allah (SWT) is always with you, even in the hardest moments. Take a deep breath, make du'a, and know that this too shall pass.

If you're in crisis or need immediate help, please reach out to:
🇬🇧 UK: Samaritans - 116 123 (free, 24/7)
🌍 Or your local emergency services

I'll be back to full capacity soon, insha'Allah. Stay strong, brother. 💙`;

    // Stream the fallback message word by word
    const words = fallbackMessage.split(' ');
    for (let i = 0; i < words.length; i++) {
      const word = i === 0 ? words[i] : ` ${words[i]}`;
      res.write(`data: ${JSON.stringify({ choices: [{ delta: { content: word } }] })}\n\n`);
      await new Promise(resolve => setTimeout(resolve, 50)); // Small delay between words
    }
    res.write('data: [DONE]\n\n');

    return true;
  }
}

/**
 * Enhanced Google Cloud Function that proxies chat requests to OpenRouter API
 * with intelligent fallbacks, rate limiting, and caching
 */
async function chatProxy(req, res) {
  // Set CORS headers to allow cross-origin requests
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, X-User-ID');

  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Handle status endpoint
  if (req.method === 'GET' && req.path === '/status') {
    return await proxyStatus(req, res);
  }

  // Validate HTTP method for chat endpoint
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed. Use POST for chat, GET for /status.' });
    return;
  }

  // Validate environment variables
  if (!process.env.OPENROUTER_API_KEY) {
    console.error('OPENROUTER_API_KEY environment variable is not set');
    res.status(500).json({ error: 'Server configuration error' });
    return;
  }

  const fallbackModels = getFallbackModels();
  if (fallbackModels.length === 0) {
    console.error('No fallback models configured');
    res.status(500).json({ error: 'Server configuration error' });
    return;
  }

  try {
    // Parse and validate request body
    const { history, prompt } = req.body;
    const userId = req.headers['x-user-id'] || 'anonymous';

    if (!prompt || typeof prompt !== 'string') {
      res.status(400).json({ error: 'Missing or invalid prompt in request body' });
      return;
    }

    if (!Array.isArray(history)) {
      res.status(400).json({ error: 'Missing or invalid history in request body' });
      return;
    }

    // Check for prompt deduplication
    if (process.env.ENABLE_PROMPT_DEDUPLICATION === 'true') {
      const deduplicationKey = generateDeduplicationKey(prompt, userId);
      if (promptDeduplicationCache.get(deduplicationKey)) {
        console.log('Duplicate prompt detected, skipping');
        res.status(429).json({ error: 'Duplicate request detected. Please wait before sending the same message again.' });
        return;
      }
      promptDeduplicationCache.set(deduplicationKey, true);
    }

    // Set Server-Sent Events headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Connection', 'keep-alive');

    // Prepare messages for OpenRouter API
    const messages = [
      ...history,
      { role: 'user', content: prompt }
    ];

    // Get the best available model
    const selectedModel = getBestAvailableModel();
    console.log(`Selected model: ${selectedModel}`);

    // Use enhanced streaming with fallback support
    const success = await streamChatWithFallback(selectedModel, messages, res);

    if (success) {
      res.end();
    } else {
      if (!res.headersSent) {
        res.status(500).json({ error: 'All models failed' });
      } else {
        res.end();
      }
    }

    // Handle client disconnect
    req.on('close', () => {
      console.log('Client disconnected');
    });

  } catch (error) {
    console.error('Chat proxy error:', error);

    if (!res.headersSent) {
      res.status(500).json({
        error: 'Internal server error',
        message: error.message
      });
    } else {
      res.end();
    }
  }
}

/**
 * Status endpoint for monitoring proxy health and model status
 */
async function proxyStatus(req, res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed. Use GET.' });
    return;
  }

  try {
    const fallbackModels = getFallbackModels();
    const modelStatuses = {};

    fallbackModels.forEach(model => {
      const status = modelStatus.get(model);
      modelStatuses[model] = status || { status: 'unknown', lastCheck: null };
    });

    const response = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      configuration: {
        fallbackModels: fallbackModels,
        rateLimitEnabled: !!process.env.RATE_LIMIT_REQUESTS_PER_MINUTE,
        cachingEnabled: process.env.ENABLE_PROMPT_DEDUPLICATION === 'true',
        queueingEnabled: process.env.ENABLE_REQUEST_QUEUEING === 'true'
      },
      modelStatuses: modelStatuses,
      cacheStats: {
        responseCache: {
          keys: responseCache.keys().length,
          hits: responseCache.getStats().hits || 0,
          misses: responseCache.getStats().misses || 0
        },
        deduplicationCache: {
          keys: promptDeduplicationCache.keys().length
        }
      },
      rateLimiter: {
        running: limiter.running(),
        queued: limiter.queued()
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Status endpoint error:', error);
    res.status(500).json({
      error: 'Status check failed',
      message: error.message
    });
  }
}

// Register the HTTP function (handles both chat and status endpoints)
if (functionsFramework && functionsFramework.http) {
  functionsFramework.http('chatProxy', chatProxy);
}

// Export functions for testing
module.exports = {
  chatProxy,
  proxyStatus,
  // Utility functions for testing
  generateCacheKey,
  generateDeduplicationKey,
  isRateLimitOrModelError,
  getNextFallbackModel,
  markModelAsWorking,
  markModelAsFailed,
  getBestAvailableModel
};

