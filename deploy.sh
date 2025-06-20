#!/bin/bash

# Enhanced deployment script for chatProxy Google Cloud Function
# Usage: ./deploy.sh [OPENROUTER_API_KEY] [DEFAULT_MODEL] [FALLBACK_MODELS]

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <OPENROUTER_API_KEY> <DEFAULT_MODEL> [FALLBACK_MODELS]"
    echo "Example: $0 'your-api-key-here' 'deepseek/deepseek-r1-0528-qwen3-8b:free' 'model1,model2,model3'"
    exit 1
fi

OPENROUTER_API_KEY="$1"
DEFAULT_MODEL="$2"
FALLBACK_MODELS="${3:-$DEFAULT_MODEL,qwen/qwen-2.5-72b-instruct:free,qwen/qwen-2.5-32b-instruct:free}"

echo "Deploying Enhanced chatProxy Google Cloud Function..."
echo "Primary Model: $DEFAULT_MODEL"
echo "Fallback Models: $FALLBACK_MODELS"

# Prepare environment variables
ENV_VARS="OPENROUTER_API_KEY=$OPENROUTER_API_KEY"
ENV_VARS="$ENV_VARS,DEFAULT_MODEL=$DEFAULT_MODEL"
ENV_VARS="$ENV_VARS,FALLBACK_MODELS=$FALLBACK_MODELS"
ENV_VARS="$ENV_VARS,RATE_LIMIT_REQUESTS_PER_MINUTE=30"
ENV_VARS="$ENV_VARS,RATE_LIMIT_BURST_SIZE=5"
ENV_VARS="$ENV_VARS,THROTTLE_DELAY_MS=1000"
ENV_VARS="$ENV_VARS,CACHE_TTL_SECONDS=300"
ENV_VARS="$ENV_VARS,CACHE_MAX_ENTRIES=1000"
ENV_VARS="$ENV_VARS,ENABLE_PROMPT_DEDUPLICATION=true"
ENV_VARS="$ENV_VARS,DEDUPLICATION_WINDOW_MS=5000"
ENV_VARS="$ENV_VARS,ENABLE_REQUEST_QUEUEING=true"
ENV_VARS="$ENV_VARS,MAX_CONCURRENT_REQUESTS=3"
ENV_VARS="$ENV_VARS,REQUEST_TIMEOUT_MS=30000"

# Deploy the main chat function
echo "Deploying chatProxy function..."
gcloud functions deploy chatProxy \
  --runtime nodejs18 \
  --trigger-http \
  --allow-unauthenticated \
  --memory 512MB \
  --timeout 540s \
  --set-env-vars "$ENV_VARS" \
  --source . \
  --entry-point chatProxy

# Deploy the status function
echo "Deploying proxyStatus function..."
gcloud functions deploy proxyStatus \
  --runtime nodejs18 \
  --trigger-http \
  --allow-unauthenticated \
  --memory 256MB \
  --timeout 60s \
  --set-env-vars "$ENV_VARS" \
  --source . \
  --entry-point proxyStatus

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "Your function is now available at:"
    gcloud functions describe chatProxy --format="value(httpsTrigger.url)"
    echo ""
    echo "Test with:"
    echo "curl -X POST [FUNCTION_URL] \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -d '{\"history\":[],\"prompt\":\"Hello!\"}'"
else
    echo "❌ Deployment failed!"
    exit 1
fi
