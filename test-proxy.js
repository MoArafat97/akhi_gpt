// Load environment variables for testing
require('dotenv').config();

// Mock the functions framework to avoid import errors during testing
const mockFunctionsFramework = {
  http: (name, handler) => {
    console.log(`Registered function: ${name}`);
  }
};

// Temporarily replace the functions framework
const originalRequire = require;
require = function(id) {
  if (id === '@google-cloud/functions-framework') {
    return { functionsFramework: mockFunctionsFramework };
  }
  return originalRequire.apply(this, arguments);
};

// Now import the index.js module
const {
  generateCacheKey,
  generateDeduplicationKey,
  isRateLimitOrModelError,
  getNextFallbackModel,
  markModelAsWorking,
  markModelAsFailed,
  getBestAvailableModel
} = require('./index.js');

// Restore original require
require = originalRequire;

/**
 * Test suite for enhanced proxy functionality
 */
async function runTests() {
  console.log('🧪 Starting Enhanced Proxy Tests...\n');

  // Test 1: Cache Key Generation
  console.log('Test 1: Cache Key Generation');
  try {
    const messages = [
      { role: 'system', content: 'You are a helpful assistant' },
      { role: 'user', content: 'Hello' }
    ];
    const cacheKey = generateCacheKey('test-model', messages);
    console.log(`✅ Cache key generated: ${cacheKey.substring(0, 20)}...`);
  } catch (error) {
    console.log(`❌ Cache key generation failed: ${error.message}`);
  }

  // Test 2: Deduplication Key Generation
  console.log('\nTest 2: Deduplication Key Generation');
  try {
    const deduplicationKey = generateDeduplicationKey('Hello world', 'user123');
    console.log(`✅ Deduplication key generated: ${deduplicationKey.substring(0, 20)}...`);
  } catch (error) {
    console.log(`❌ Deduplication key generation failed: ${error.message}`);
  }

  // Test 3: Rate Limit Error Detection
  console.log('\nTest 3: Rate Limit Error Detection');
  try {
    const rateLimitError = { status: 429 };
    const isRateLimit = isRateLimitOrModelError(rateLimitError, null);
    console.log(`✅ Rate limit detection: ${isRateLimit}`);

    const quotaError = isRateLimitOrModelError(null, 'quota exceeded');
    console.log(`✅ Quota error detection: ${quotaError}`);
  } catch (error) {
    console.log(`❌ Error detection failed: ${error.message}`);
  }

  // Test 4: Fallback Model Logic
  console.log('\nTest 4: Fallback Model Logic');
  try {
    // Set up test environment
    process.env.FALLBACK_MODELS = 'model1,model2,model3';
    
    const nextModel = getNextFallbackModel('model1');
    console.log(`✅ Next fallback model: ${nextModel}`);

    const noFallback = getNextFallbackModel('model3');
    console.log(`✅ No more fallbacks: ${noFallback}`);
  } catch (error) {
    console.log(`❌ Fallback model logic failed: ${error.message}`);
  }

  // Test 5: Model Status Management
  console.log('\nTest 5: Model Status Management');
  try {
    markModelAsWorking('test-model');
    console.log('✅ Model marked as working');

    markModelAsFailed('test-model');
    console.log('✅ Model marked as failed');

    const bestModel = getBestAvailableModel();
    console.log(`✅ Best available model: ${bestModel}`);
  } catch (error) {
    console.log(`❌ Model status management failed: ${error.message}`);
  }

  // Test 6: Environment Configuration
  console.log('\nTest 6: Environment Configuration');
  try {
    const requiredVars = [
      'OPENROUTER_API_KEY',
      'DEFAULT_MODEL',
      'FALLBACK_MODELS',
      'RATE_LIMIT_REQUESTS_PER_MINUTE',
      'CACHE_TTL_SECONDS'
    ];

    for (const varName of requiredVars) {
      const value = process.env[varName];
      if (value) {
        console.log(`✅ ${varName}: ${varName.includes('KEY') ? '[HIDDEN]' : value}`);
      } else {
        console.log(`⚠️  ${varName}: Not set`);
      }
    }
  } catch (error) {
    console.log(`❌ Environment configuration check failed: ${error.message}`);
  }

  // Test 7: Proxy Health Check
  console.log('\nTest 7: Proxy Health Check');
  try {
    const fetch = require('node-fetch').default;
    const proxyEndpoint = process.env.PROXY_ENDPOINT || 'http://localhost:8080';
    
    console.log(`Checking proxy health at: ${proxyEndpoint}`);
    
    // This test requires the proxy to be running
    try {
      const response = await fetch(`${proxyEndpoint}/status`, {
        method: 'GET',
        timeout: 5000
      });
      
      if (response.ok) {
        const status = await response.json();
        console.log('✅ Proxy is healthy');
        console.log(`   Status: ${status.status}`);
        console.log(`   Models: ${status.configuration?.fallbackModels?.length || 0}`);
      } else {
        console.log(`⚠️  Proxy returned status: ${response.status}`);
      }
    } catch (fetchError) {
      console.log(`⚠️  Proxy not available: ${fetchError.message}`);
    }
  } catch (error) {
    console.log(`❌ Proxy health check failed: ${error.message}`);
  }

  console.log('\n🏁 Enhanced Proxy Tests Completed!');
}

// Test the chat proxy endpoint
async function testChatEndpoint() {
  console.log('\n🔄 Testing Chat Endpoint...');
  
  try {
    const fetch = require('node-fetch').default;
    const proxyEndpoint = process.env.PROXY_ENDPOINT || 'http://localhost:8080';
    
    const testPayload = {
      history: [
        { role: 'system', content: 'You are a helpful assistant.' }
      ],
      prompt: 'Hello, this is a test message.'
    };

    console.log(`Sending test request to: ${proxyEndpoint}`);
    
    const response = await fetch(proxyEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-User-ID': 'test-user'
      },
      body: JSON.stringify(testPayload),
      timeout: 10000
    });

    if (response.ok) {
      console.log('✅ Chat endpoint responded successfully');
      console.log(`   Status: ${response.status}`);
      console.log(`   Content-Type: ${response.headers.get('content-type')}`);
      
      // Read a few chunks of the stream
      const reader = response.body;
      let chunkCount = 0;
      
      reader.on('data', (chunk) => {
        if (chunkCount < 3) {
          console.log(`   Chunk ${chunkCount + 1}: ${chunk.toString().substring(0, 50)}...`);
          chunkCount++;
        }
      });
      
      reader.on('end', () => {
        console.log('✅ Stream completed successfully');
      });
      
    } else {
      console.log(`❌ Chat endpoint failed: ${response.status}`);
      const errorText = await response.text();
      console.log(`   Error: ${errorText.substring(0, 100)}...`);
    }
  } catch (error) {
    console.log(`❌ Chat endpoint test failed: ${error.message}`);
  }
}

// Run the tests
if (require.main === module) {
  runTests()
    .then(() => testChatEndpoint())
    .catch(console.error);
}

module.exports = { runTests, testChatEndpoint };
