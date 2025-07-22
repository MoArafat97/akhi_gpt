#!/bin/bash

# Demo Script for NafsAI Code Quality Monitoring
# This script demonstrates all the quality monitoring features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}🎯 NafsAI Code Quality Monitoring Demo${NC}"
echo -e "${PURPLE}======================================${NC}\n"

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}📋 $1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_section "1. SETUP VERIFICATION"

echo -e "${YELLOW}Checking required files...${NC}"

# Check all required files
files=(
    "coverage_config.yaml"
    "quality_gates.yaml"
    "sonar-project.properties"
    "docker-compose.sonar.yml"
    "scripts/coverage.sh"
    "scripts/quality_check.sh"
    "scripts/sonar_setup.sh"
    "CODE_QUALITY_GUIDE.md"
    "test/code_quality_test.dart"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ✅ $file"
    else
        echo -e "  ❌ $file (missing)"
    fi
done

echo -e "\n${YELLOW}Checking script permissions...${NC}"
scripts=("scripts/coverage.sh" "scripts/quality_check.sh" "scripts/sonar_setup.sh")
for script in "${scripts[@]}"; do
    if [ -x "$script" ]; then
        echo -e "  ✅ $script (executable)"
    else
        echo -e "  ⚠️  $script (not executable - run: chmod +x $script)"
    fi
done

print_section "2. COVERAGE CONFIGURATION"

echo -e "${YELLOW}Coverage configuration highlights:${NC}"
if [ -f "coverage_config.yaml" ]; then
    echo -e "  📊 Line coverage minimum: 80%"
    echo -e "  📊 Function coverage minimum: 85%"
    echo -e "  📊 Branch coverage minimum: 75%"
    echo -e "  🔒 Critical services coverage: 95%+"
    echo -e "  🛡️  Security components coverage: 98%+"
    echo -e "  📁 Excludes generated files (*.g.dart, *.mocks.dart)"
    echo -e "  📁 Supports multiple test types (unit, widget, integration)"
else
    echo -e "  ❌ Coverage configuration not found"
fi

print_section "3. QUALITY GATES"

echo -e "${YELLOW}Quality gate enforcement:${NC}"
if [ -f "quality_gates.yaml" ]; then
    echo -e "  🚪 Automated quality enforcement before deployment"
    echo -e "  📈 Maintainability rating: A required"
    echo -e "  🐛 Zero bugs policy for new code"
    echo -e "  🔒 Zero security vulnerabilities allowed"
    echo -e "  📊 Code duplication limit: 3%"
    echo -e "  🧠 Complexity limits: 10 (general), 8 (critical services)"
    echo -e "  ⚡ Performance monitoring included"
else
    echo -e "  ❌ Quality gates configuration not found"
fi

print_section "4. SONARQUBE INTEGRATION"

echo -e "${YELLOW}SonarQube features:${NC}"
if [ -f "sonar-project.properties" ]; then
    echo -e "  🔍 Comprehensive static analysis"
    echo -e "  🛡️  Security vulnerability detection"
    echo -e "  📊 Technical debt measurement"
    echo -e "  🔄 CI/CD integration ready"
    echo -e "  🐳 Docker-based local development"
    echo -e "  📈 Quality trend monitoring"
    echo -e "  🎯 Flutter-specific rules and thresholds"
else
    echo -e "  ❌ SonarQube configuration not found"
fi

print_section "5. CI/CD INTEGRATION"

echo -e "${YELLOW}GitHub Actions workflow enhancements:${NC}"
if [ -f ".github/workflows/build-and-deploy.yml" ]; then
    echo -e "  ✅ Quality gates job added"
    echo -e "  ✅ SonarQube analysis job added"
    echo -e "  ✅ Coverage reporting integrated"
    echo -e "  ✅ Build jobs depend on quality gates"
    echo -e "  ✅ Deployment blocked on quality failures"
    echo -e "  ✅ Security scanning enhanced"
else
    echo -e "  ❌ GitHub Actions workflow not found"
fi

print_section "6. SECURITY MONITORING"

echo -e "${YELLOW}Security features:${NC}"
echo -e "  🔐 Hardcoded API key detection"
echo -e "  🛡️  Secure storage enforcement"
echo -e "  🔒 Encryption requirement validation"
echo -e "  🌐 HTTPS-only communication checks"
echo -e "  🔍 Security hotspot identification"
echo -e "  📋 Security rating enforcement (A required)"

print_section "7. CRITICAL SERVICES MONITORING"

echo -e "${YELLOW}High-standard monitoring for:${NC}"
echo -e "  🔌 OpenRouter API service (95% coverage)"
echo -e "  💳 Subscription service (95% coverage)"
echo -e "  🔐 Encryption service (98% coverage)"
echo -e "  ⚙️  Secure config service (98% coverage)"
echo -e "  🔑 User API key service (98% coverage)"
echo -e "  🔍 Diagnostic service (95% coverage)"

print_section "8. USAGE EXAMPLES"

echo -e "${YELLOW}How to use the quality monitoring system:${NC}\n"

echo -e "${CYAN}Local Development:${NC}"
echo -e "  # Run comprehensive coverage analysis"
echo -e "  ./scripts/coverage.sh"
echo -e ""
echo -e "  # Check quality gates before committing"
echo -e "  ./scripts/quality_check.sh"
echo -e ""
echo -e "  # Setup local SonarQube"
echo -e "  ./scripts/sonar_setup.sh setup"
echo -e ""
echo -e "  # Run SonarQube analysis"
echo -e "  ./scripts/sonar_setup.sh analyze"

echo -e "\n${CYAN}CI/CD Pipeline:${NC}"
echo -e "  # Quality gates run automatically on:"
echo -e "  - Every pull request"
echo -e "  - Every push to main/develop"
echo -e "  - Before any deployment"

echo -e "\n${CYAN}Viewing Reports:${NC}"
echo -e "  # Coverage report: coverage/html/index.html"
echo -e "  # SonarQube dashboard: http://localhost:9000"
echo -e "  # GitHub Actions: Repository → Actions tab"

print_section "9. QUALITY THRESHOLDS SUMMARY"

echo -e "${YELLOW}Minimum requirements:${NC}"
cat << 'EOF'
┌─────────────────────────┬──────────┬──────────┬──────────┐
│ Component Type          │ Line %   │ Function │ Branch % │
├─────────────────────────┼──────────┼──────────┼──────────┤
│ Critical Services       │    95%   │    98%   │    90%   │
│ Security Components     │    98%   │    98%   │    95%   │
│ UI Components           │    75%   │    80%   │    70%   │
│ Utilities               │    85%   │    90%   │    80%   │
│ Overall Project         │    80%   │    85%   │    75%   │
└─────────────────────────┴──────────┴──────────┴──────────┘
EOF

print_section "10. NEXT STEPS"

echo -e "${YELLOW}To get started:${NC}"
echo -e "  1. Run: ${CYAN}flutter pub get${NC}"
echo -e "  2. Run: ${CYAN}./scripts/coverage.sh${NC}"
echo -e "  3. Run: ${CYAN}./scripts/quality_check.sh${NC}"
echo -e "  4. Setup SonarQube: ${CYAN}./scripts/sonar_setup.sh setup${NC}"
echo -e "  5. Review reports and improve code quality"

echo -e "\n${YELLOW}For CI/CD setup:${NC}"
echo -e "  1. Add GitHub secrets:"
echo -e "     - SONAR_TOKEN"
echo -e "     - SONAR_HOST_URL"
echo -e "  2. Push changes to trigger quality gates"
echo -e "  3. Monitor quality trends in SonarQube"

echo -e "\n${YELLOW}Documentation:${NC}"
echo -e "  📖 Read: ${CYAN}CODE_QUALITY_GUIDE.md${NC}"
echo -e "  🧪 Run: ${CYAN}flutter test test/code_quality_test.dart${NC}"

print_section "DEMO COMPLETE"

echo -e "${GREEN}🎉 Your NafsAI project now has enterprise-grade code quality monitoring!${NC}"
echo -e "${GREEN}✨ Features include comprehensive coverage, quality gates, and SonarQube integration${NC}"
echo -e "${GREEN}🚀 Ready for production deployment with automated quality enforcement${NC}\n"

echo -e "${PURPLE}For questions or issues, refer to the CODE_QUALITY_GUIDE.md${NC}"
