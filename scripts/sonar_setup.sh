#!/bin/bash

# SonarQube Setup Script for NafsAI
# This script sets up SonarQube for local development and CI/CD integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SONAR_URL="http://localhost:9000"
SONAR_PROJECT_KEY="nafs-ai"
SONAR_PROJECT_NAME="NafsAI - Muslim Companion App"
DOCKER_COMPOSE_FILE="docker-compose.sonar.yml"

echo -e "${BLUE}🔧 Setting up SonarQube for NafsAI...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for SonarQube to be ready
wait_for_sonarqube() {
    echo -e "${YELLOW}⏳ Waiting for SonarQube to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f "$SONAR_URL/api/system/status" 2>/dev/null | grep -q '"status":"UP"'; then
            echo -e "${GREEN}✅ SonarQube is ready!${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}Attempt $attempt/$max_attempts - SonarQube not ready yet...${NC}"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ SonarQube failed to start within expected time${NC}"
    return 1
}

# Function to create SonarQube project
create_sonar_project() {
    echo -e "${BLUE}📋 Creating SonarQube project...${NC}"
    
    # Default credentials for local SonarQube
    local auth="admin:admin"
    
    # Create project
    local response
    response=$(curl -s -u "$auth" -X POST "$SONAR_URL/api/projects/create" \
        -d "project=$SONAR_PROJECT_KEY" \
        -d "name=$SONAR_PROJECT_NAME" \
        -w "%{http_code}")
    
    local http_code="${response: -3}"
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "400" ]; then
        echo -e "${GREEN}✅ Project created or already exists${NC}"
    else
        echo -e "${RED}❌ Failed to create project (HTTP $http_code)${NC}"
        return 1
    fi
    
    # Generate token
    echo -e "${BLUE}🔑 Generating authentication token...${NC}"
    local token_response
    token_response=$(curl -s -u "$auth" -X POST "$SONAR_URL/api/user_tokens/generate" \
        -d "name=nafs-ai-token" \
        -d "type=PROJECT_ANALYSIS_TOKEN" \
        -d "projectKey=$SONAR_PROJECT_KEY")
    
    local token
    token=$(echo "$token_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$token" ]; then
        echo -e "${GREEN}✅ Token generated successfully${NC}"
        echo -e "${YELLOW}📝 Save this token for CI/CD: $token${NC}"
        
        # Save token to .env.sonar for local use
        echo "SONAR_TOKEN=$token" > .env.sonar
        echo -e "${BLUE}💾 Token saved to .env.sonar${NC}"
    else
        echo -e "${RED}❌ Failed to generate token${NC}"
        return 1
    fi
}

# Function to install SonarQube scanner
install_sonar_scanner() {
    echo -e "${BLUE}📥 Installing SonarQube Scanner...${NC}"
    
    if command_exists sonar-scanner; then
        echo -e "${GREEN}✅ SonarQube Scanner already installed${NC}"
        return 0
    fi
    
    # Install based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install sonar-scanner
        else
            echo -e "${RED}❌ Homebrew not found. Please install Homebrew first.${NC}"
            return 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Download and install SonarQube Scanner
        local scanner_version="5.0.1.3006"
        local scanner_dir="/opt/sonar-scanner"
        
        if [ ! -d "$scanner_dir" ]; then
            sudo mkdir -p "$scanner_dir"
            cd /tmp
            wget "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${scanner_version}-linux.zip"
            unzip "sonar-scanner-cli-${scanner_version}-linux.zip"
            sudo mv "sonar-scanner-${scanner_version}-linux"/* "$scanner_dir/"
            sudo ln -sf "$scanner_dir/bin/sonar-scanner" /usr/local/bin/sonar-scanner
            cd - > /dev/null
        fi
    else
        echo -e "${RED}❌ Unsupported operating system${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ SonarQube Scanner installed${NC}"
}

# Function to setup local SonarQube with Docker
setup_local_sonarqube() {
    echo -e "${BLUE}🐳 Setting up local SonarQube with Docker...${NC}"
    
    # Check if Docker is available
    if ! command_exists docker; then
        echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
        return 1
    fi
    
    if ! command_exists docker-compose; then
        echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose first.${NC}"
        return 1
    fi
    
    # Start SonarQube services
    echo -e "${YELLOW}🚀 Starting SonarQube services...${NC}"
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    # Wait for SonarQube to be ready
    if wait_for_sonarqube; then
        # Create project and generate token
        create_sonar_project
    else
        echo -e "${RED}❌ Failed to start SonarQube${NC}"
        return 1
    fi
}

# Function to run SonarQube analysis
run_sonar_analysis() {
    echo -e "${BLUE}🔍 Running SonarQube analysis...${NC}"
    
    # Ensure coverage data exists
    if [ ! -f "coverage/lcov.info" ]; then
        echo -e "${YELLOW}📊 Generating coverage data first...${NC}"
        ./scripts/coverage.sh
    fi
    
    # Load token from .env.sonar if it exists
    if [ -f ".env.sonar" ]; then
        source .env.sonar
    fi
    
    # Run analysis
    if [ -n "$SONAR_TOKEN" ]; then
        sonar-scanner \
            -Dsonar.host.url="$SONAR_URL" \
            -Dsonar.login="$SONAR_TOKEN"
    else
        echo -e "${YELLOW}⚠️  No token found, using default credentials${NC}"
        sonar-scanner \
            -Dsonar.host.url="$SONAR_URL" \
            -Dsonar.login=admin \
            -Dsonar.password=admin
    fi
    
    echo -e "${GREEN}✅ SonarQube analysis completed${NC}"
    echo -e "${BLUE}🌐 View results at: $SONAR_URL/dashboard?id=$SONAR_PROJECT_KEY${NC}"
}

# Function to setup CI/CD integration
setup_ci_integration() {
    echo -e "${BLUE}🔧 Setting up CI/CD integration...${NC}"
    
    cat << 'EOF' > .github/workflows/sonarqube.yml
name: SonarQube Analysis

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  FLUTTER_VERSION: '3.24.0'

jobs:
  sonarqube:
    name: SonarQube Analysis
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Shallow clones should be disabled for better analysis
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        cache: true
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Generate mocks
      run: flutter packages pub run build_runner build --delete-conflicting-outputs
    
    - name: Run tests with coverage
      run: flutter test --coverage --coverage-path=coverage/lcov.info
    
    - name: SonarQube Scan
      uses: sonarqube-quality-gate-action@master
      with:
        scanMetadataReportFile: coverage/lcov.info
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
EOF
    
    echo -e "${GREEN}✅ CI/CD workflow created${NC}"
    echo -e "${YELLOW}📝 Don't forget to add these secrets to your GitHub repository:${NC}"
    echo -e "   - SONAR_TOKEN: Your SonarQube token"
    echo -e "   - SONAR_HOST_URL: Your SonarQube server URL"
}

# Main function
main() {
    local action="${1:-setup}"
    
    case $action in
        "setup")
            echo -e "${BLUE}🚀 Setting up complete SonarQube environment...${NC}"
            setup_local_sonarqube
            install_sonar_scanner
            setup_ci_integration
            ;;
        "start")
            echo -e "${BLUE}🚀 Starting SonarQube services...${NC}"
            docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
            wait_for_sonarqube
            ;;
        "stop")
            echo -e "${BLUE}🛑 Stopping SonarQube services...${NC}"
            docker-compose -f "$DOCKER_COMPOSE_FILE" down
            ;;
        "analyze")
            run_sonar_analysis
            ;;
        "clean")
            echo -e "${BLUE}🧹 Cleaning up SonarQube environment...${NC}"
            docker-compose -f "$DOCKER_COMPOSE_FILE" down -v
            docker volume prune -f
            ;;
        *)
            echo -e "${YELLOW}Usage: $0 {setup|start|stop|analyze|clean}${NC}"
            echo -e "  setup   - Complete SonarQube setup"
            echo -e "  start   - Start SonarQube services"
            echo -e "  stop    - Stop SonarQube services"
            echo -e "  analyze - Run SonarQube analysis"
            echo -e "  clean   - Clean up all SonarQube data"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
