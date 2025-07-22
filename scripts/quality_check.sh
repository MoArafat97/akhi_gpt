#!/bin/bash

# Quality Gates Enforcement Script for NafsAI
# This script enforces quality standards before allowing deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
QUALITY_CONFIG="quality_gates.yaml"
COVERAGE_DIR="coverage"
LCOV_FILE="$COVERAGE_DIR/lcov.info"

# Quality thresholds (loaded from config)
MIN_LINE_COVERAGE=80
MIN_FUNCTION_COVERAGE=85
MIN_BRANCH_COVERAGE=75
MAX_COMPLEXITY=10
MAX_DUPLICATION=3.0
MAX_TECHNICAL_DEBT=5.0

echo -e "${BLUE}🚪 Running Quality Gates for NafsAI...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to extract coverage percentage from LCOV
extract_coverage() {
    local lcov_file="$1"
    local type="$2"  # lines, functions, branches
    
    if [ ! -f "$lcov_file" ]; then
        echo "0"
        return
    fi
    
    case $type in
        "lines")
            lcov --summary "$lcov_file" 2>/dev/null | grep -o 'lines......: [0-9.]*%' | grep -o '[0-9.]*' | head -1 || echo "0"
            ;;
        "functions")
            lcov --summary "$lcov_file" 2>/dev/null | grep -o 'functions..: [0-9.]*%' | grep -o '[0-9.]*' | head -1 || echo "0"
            ;;
        "branches")
            lcov --summary "$lcov_file" 2>/dev/null | grep -o 'branches...: [0-9.]*%' | grep -o '[0-9.]*' | head -1 || echo "0"
            ;;
    esac
}

# Function to check code complexity
check_complexity() {
    echo -e "${BLUE}🔍 Checking code complexity...${NC}"
    
    # Use dart analyze to check for complexity issues
    local complexity_issues=0
    
    # Run dart analyze and capture output
    if ! flutter analyze --no-fatal-infos > /tmp/analyze_output.txt 2>&1; then
        complexity_issues=$(grep -c "complexity" /tmp/analyze_output.txt || echo "0")
    fi
    
    if [ "$complexity_issues" -gt 0 ]; then
        echo -e "${RED}❌ Found $complexity_issues complexity issues${NC}"
        cat /tmp/analyze_output.txt | grep "complexity" || true
        return 1
    else
        echo -e "${GREEN}✅ Code complexity within acceptable limits${NC}"
        return 0
    fi
}

# Function to check for code duplication
check_duplication() {
    echo -e "${BLUE}🔍 Checking for code duplication...${NC}"
    
    # Simple duplication check using grep and sort
    local duplicate_lines=0
    local total_lines=0
    
    # Count total lines of code (excluding comments and empty lines)
    total_lines=$(find lib -name "*.dart" -not -path "*/.*" -exec grep -v "^\s*$\|^\s*//" {} \; | wc -l)
    
    if [ "$total_lines" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No code found to analyze${NC}"
        return 0
    fi
    
    # Simple duplication detection (lines appearing more than once)
    duplicate_lines=$(find lib -name "*.dart" -not -path "*/.*" -exec grep -v "^\s*$\|^\s*//" {} \; | sort | uniq -d | wc -l)
    
    local duplication_percentage
    duplication_percentage=$(echo "scale=2; ($duplicate_lines * 100) / $total_lines" | bc -l 2>/dev/null || echo "0")
    
    echo -e "Duplication: ${duplication_percentage}% (${duplicate_lines}/${total_lines} lines)"
    
    if (( $(echo "$duplication_percentage > $MAX_DUPLICATION" | bc -l) )); then
        echo -e "${RED}❌ Code duplication exceeds threshold (${MAX_DUPLICATION}%)${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Code duplication within acceptable limits${NC}"
        return 0
    fi
}

# Function to check security issues
check_security() {
    echo -e "${BLUE}🔒 Running security checks...${NC}"
    
    local security_issues=0
    
    # Check for hardcoded API keys
    if grep -r "sk-or-v1-" lib/ --exclude-dir=.git >/dev/null 2>&1; then
        echo -e "${RED}❌ Found hardcoded API keys${NC}"
        security_issues=$((security_issues + 1))
    fi
    
    # Check for placeholder API keys
    if grep -r "your-.*-api-key-here" lib/ --exclude-dir=.git >/dev/null 2>&1; then
        echo -e "${RED}❌ Found placeholder API keys${NC}"
        security_issues=$((security_issues + 1))
    fi
    
    # Check for TODO/FIXME related to security
    local security_todos
    security_todos=$(grep -r "TODO.*security\|FIXME.*security\|TODO.*encrypt\|FIXME.*encrypt" lib/ --exclude-dir=.git | wc -l)
    
    if [ "$security_todos" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $security_todos security-related TODOs/FIXMEs${NC}"
        grep -r "TODO.*security\|FIXME.*security\|TODO.*encrypt\|FIXME.*encrypt" lib/ --exclude-dir=.git || true
    fi
    
    # Check for insecure HTTP usage
    if grep -r "http://" lib/ --exclude-dir=.git >/dev/null 2>&1; then
        echo -e "${RED}❌ Found insecure HTTP URLs${NC}"
        security_issues=$((security_issues + 1))
    fi
    
    if [ "$security_issues" -eq 0 ]; then
        echo -e "${GREEN}✅ No security issues found${NC}"
        return 0
    else
        echo -e "${RED}❌ Found $security_issues security issues${NC}"
        return 1
    fi
}

# Function to run all tests
run_tests() {
    echo -e "${BLUE}🧪 Running all tests...${NC}"
    
    # Get dependencies first
    flutter pub get
    
    # Generate mocks if needed
    if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
        echo -e "${YELLOW}🔧 Generating mocks...${NC}"
        flutter packages pub run build_runner build --delete-conflicting-outputs
    fi
    
    # Run tests with coverage
    if ! flutter test --coverage --coverage-path="$LCOV_FILE"; then
        echo -e "${RED}❌ Tests failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All tests passed${NC}"
    return 0
}

# Main quality gate checks
main() {
    local exit_code=0
    
    echo -e "${BLUE}🚀 Starting Quality Gate Analysis...${NC}"
    
    # 1. Run tests and generate coverage
    if ! run_tests; then
        echo -e "${RED}❌ QUALITY GATE FAILED: Tests failed${NC}"
        exit_code=1
    fi
    
    # 2. Check coverage thresholds
    if [ -f "$LCOV_FILE" ]; then
        echo -e "${BLUE}📊 Checking coverage thresholds...${NC}"
        
        local line_coverage
        local function_coverage
        local branch_coverage
        
        line_coverage=$(extract_coverage "$LCOV_FILE" "lines")
        function_coverage=$(extract_coverage "$LCOV_FILE" "functions")
        branch_coverage=$(extract_coverage "$LCOV_FILE" "branches")
        
        echo -e "Line Coverage: ${line_coverage}%"
        echo -e "Function Coverage: ${function_coverage}%"
        echo -e "Branch Coverage: ${branch_coverage}%"
        
        # Check line coverage
        if (( $(echo "$line_coverage < $MIN_LINE_COVERAGE" | bc -l) )); then
            echo -e "${RED}❌ QUALITY GATE FAILED: Line coverage ${line_coverage}% below threshold ${MIN_LINE_COVERAGE}%${NC}"
            exit_code=1
        else
            echo -e "${GREEN}✅ Line coverage meets threshold${NC}"
        fi
        
        # Check function coverage
        if (( $(echo "$function_coverage < $MIN_FUNCTION_COVERAGE" | bc -l) )); then
            echo -e "${RED}❌ QUALITY GATE FAILED: Function coverage ${function_coverage}% below threshold ${MIN_FUNCTION_COVERAGE}%${NC}"
            exit_code=1
        else
            echo -e "${GREEN}✅ Function coverage meets threshold${NC}"
        fi
        
        # Check branch coverage (if available)
        if [ "$branch_coverage" != "0" ] && (( $(echo "$branch_coverage < $MIN_BRANCH_COVERAGE" | bc -l) )); then
            echo -e "${RED}❌ QUALITY GATE FAILED: Branch coverage ${branch_coverage}% below threshold ${MIN_BRANCH_COVERAGE}%${NC}"
            exit_code=1
        elif [ "$branch_coverage" != "0" ]; then
            echo -e "${GREEN}✅ Branch coverage meets threshold${NC}"
        fi
    else
        echo -e "${RED}❌ QUALITY GATE FAILED: No coverage data found${NC}"
        exit_code=1
    fi
    
    # 3. Check code complexity
    if ! check_complexity; then
        echo -e "${RED}❌ QUALITY GATE FAILED: Code complexity issues${NC}"
        exit_code=1
    fi
    
    # 4. Check code duplication
    if ! check_duplication; then
        echo -e "${RED}❌ QUALITY GATE FAILED: Code duplication issues${NC}"
        exit_code=1
    fi
    
    # 5. Run security checks
    if ! check_security; then
        echo -e "${RED}❌ QUALITY GATE FAILED: Security issues${NC}"
        exit_code=1
    fi
    
    # 6. Run static analysis
    echo -e "${BLUE}🔍 Running static analysis...${NC}"
    if ! flutter analyze --fatal-infos; then
        echo -e "${RED}❌ QUALITY GATE FAILED: Static analysis issues${NC}"
        exit_code=1
    else
        echo -e "${GREEN}✅ Static analysis passed${NC}"
    fi
    
    # Final result
    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}🎉 ALL QUALITY GATES PASSED!${NC}"
        echo -e "${GREEN}✅ Code is ready for deployment${NC}"
    else
        echo -e "\n${RED}❌ QUALITY GATES FAILED!${NC}"
        echo -e "${RED}🚫 Code is not ready for deployment${NC}"
        echo -e "${YELLOW}📋 Please fix the issues above before proceeding${NC}"
    fi
    
    return $exit_code
}

# Install dependencies if needed
if ! command_exists bc; then
    echo -e "${YELLOW}📥 Installing bc for calculations...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install bc
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y bc
    fi
fi

# Run main function
main "$@"
