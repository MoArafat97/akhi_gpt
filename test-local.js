/**
 * Simple test script to verify the chatProxy function works locally
 * Run with: node test-local.js
 */

// Set test environment variables
process.env.OPENROUTER_API_KEY = 'test-key';
process.env.DEFAULT_MODEL = 'deepseek-r1';

const { chatProxy } = require('./index.js');

// Mock request and response objects
const mockReq = {
  method: 'POST',
  body: {
    history: [
      { role: 'system', content: 'You are a helpful assistant.' }
    ],
    prompt: 'Hello, how are you?'
  },
  on: (event, callback) => {
    // Mock client disconnect handling
    if (event === 'close') {
      console.log('Mock: Client disconnect handler registered');
    }
  }
};

const mockRes = {
  headersSent: false,
  finished: false,
  headers: {},
  
  set: function(key, value) {
    this.headers[key] = value;
    console.log(`Header set: ${key} = ${value}`);
  },
  
  setHeader: function(key, value) {
    this.headers[key] = value;
    console.log(`Header set: ${key} = ${value}`);
  },
  
  status: function(code) {
    this.statusCode = code;
    console.log(`Status set: ${code}`);
    return this;
  },
  
  json: function(data) {
    console.log('JSON response:', data);
    return this;
  },
  
  send: function(data) {
    console.log('Send response:', data);
    return this;
  },
  
  write: function(data) {
    console.log('Write data:', data.substring(0, 100) + '...');
  },
  
  end: function() {
    console.log('Response ended');
    this.finished = true;
  }
};

// Test the function
console.log('Testing chatProxy function...');
console.log('Note: This will fail with OpenRouter API call since we\'re using a test key');
console.log('But it should validate the request structure and setup correctly.\n');

chatProxy(mockReq, mockRes)
  .then(() => {
    console.log('\nTest completed');
  })
  .catch((error) => {
    console.log('\nExpected error (due to test API key):', error.message);
  });
