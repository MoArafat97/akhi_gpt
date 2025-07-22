# 📊 Code Quality Monitoring Guide for NafsAI

This guide explains how to use the advanced code quality monitoring system implemented for the NafsAI Flutter project.

## 🎯 Overview

Our code quality monitoring system includes:
- **Comprehensive Code Coverage** (Unit, Widget, Integration tests)
- **Quality Gates** (Automated quality enforcement)
- **SonarQube Integration** (Static analysis and security scanning)
- **CI/CD Integration** (Automated quality checks in GitHub Actions)

## 🚀 Quick Start

### 1. Local Development Setup

```bash
# Install dependencies
flutter pub get

# Make scripts executable
chmod +x scripts/*.sh

# Run comprehensive coverage analysis
./scripts/coverage.sh

# Run quality gates check
./scripts/quality_check.sh

# Setup SonarQube (one-time setup)
./scripts/sonar_setup.sh setup
```

### 2. View Coverage Reports

After running coverage analysis:
- **HTML Report**: Open `coverage/html/index.html` in your browser
- **LCOV Report**: `coverage/lcov.info` (for CI/CD integration)
- **Cobertura Report**: `coverage/cobertura.xml` (for SonarQube)

## 📊 Understanding Coverage Metrics

### Coverage Types Explained

1. **Line Coverage** (Target: 80%+)
   - Percentage of code lines executed during tests
   - Critical for ensuring all code paths are tested

2. **Function Coverage** (Target: 85%+)
   - Percentage of functions/methods called during tests
   - Ensures all functionality is exercised

3. **Branch Coverage** (Target: 75%+)
   - Percentage of decision branches taken during tests
   - Critical for testing conditional logic

### Service-Specific Targets

| Component Type | Line Coverage | Function Coverage | Branch Coverage |
|----------------|---------------|-------------------|-----------------|
| **Critical Services** | 95% | 98% | 90% |
| **Security Components** | 98% | 98% | 95% |
| **UI Components** | 75% | 80% | 70% |
| **Utilities** | 85% | 90% | 80% |

### Critical Services (Highest Standards)
- `lib/services/openrouter_service.dart`
- `lib/services/subscription_service.dart`
- `lib/services/encryption_service.dart`
- `lib/services/secure_config_service.dart`
- `lib/services/user_api_key_service.dart`
- `lib/services/diagnostic_service.dart`

## 🚪 Quality Gates

Quality gates prevent deployment of code that doesn't meet our standards.

### Automated Checks

1. **Test Success Rate**: 100% (All tests must pass)
2. **Code Coverage**: Meets minimum thresholds
3. **Static Analysis**: No critical issues
4. **Security Scan**: No vulnerabilities
5. **Code Complexity**: Within acceptable limits
6. **Code Duplication**: Below 3%

### Running Quality Gates Locally

```bash
# Run all quality checks
./scripts/quality_check.sh

# The script will:
# ✅ Run all tests with coverage
# ✅ Check coverage thresholds
# ✅ Analyze code complexity
# ✅ Detect code duplication
# ✅ Run security scans
# ✅ Perform static analysis
```

### Quality Gate Failure Resolution

If quality gates fail:

1. **Coverage Issues**:
   ```bash
   # Generate detailed coverage report
   ./scripts/coverage.sh
   # Open coverage/html/index.html to see uncovered lines
   # Add tests for uncovered code
   ```

2. **Complexity Issues**:
   ```bash
   # Run analyzer to see complexity warnings
   flutter analyze
   # Refactor complex functions (max complexity: 10)
   ```

3. **Security Issues**:
   ```bash
   # Check for hardcoded secrets
   grep -r "sk-or-v1-" lib/
   # Move secrets to secure storage or environment variables
   ```

## 🔍 SonarQube Integration

### Local SonarQube Setup

1. **Start SonarQube**:
   ```bash
   ./scripts/sonar_setup.sh start
   ```

2. **Access SonarQube**: http://localhost:9000
   - Username: `admin`
   - Password: `admin`

3. **Run Analysis**:
   ```bash
   ./scripts/sonar_setup.sh analyze
   ```

### Understanding SonarQube Reports

#### Quality Gate Status
- **Passed**: ✅ Code meets all quality standards
- **Failed**: ❌ Code has issues that need attention

#### Key Metrics

1. **Maintainability Rating** (A-E scale)
   - A: ≤5% technical debt
   - B: 6-10% technical debt
   - C: 11-20% technical debt
   - D: 21-50% technical debt
   - E: >50% technical debt

2. **Reliability Rating** (A-E scale)
   - A: 0 bugs
   - B: ≥1 minor bug
   - C: ≥1 major bug
   - D: ≥1 critical bug
   - E: ≥1 blocker bug

3. **Security Rating** (A-E scale)
   - A: 0 vulnerabilities
   - B: ≥1 minor vulnerability
   - C: ≥1 major vulnerability
   - D: ≥1 critical vulnerability
   - E: ≥1 blocker vulnerability

#### Security Hotspots
Areas of code that require security review:
- API key handling
- Data encryption
- User input validation
- Network communications

### Acting on SonarQube Findings

1. **Code Smells** (Maintainability issues):
   - Refactor complex methods
   - Remove code duplication
   - Improve naming conventions
   - Add missing documentation

2. **Bugs** (Reliability issues):
   - Fix null pointer exceptions
   - Handle edge cases
   - Correct logical errors
   - Add proper error handling

3. **Vulnerabilities** (Security issues):
   - Remove hardcoded secrets
   - Validate user inputs
   - Use secure communication
   - Implement proper authentication

## 🔄 CI/CD Integration

### GitHub Actions Workflow

Our CI/CD pipeline includes:

1. **Test Job**: Runs tests with coverage
2. **Quality Gates Job**: Enforces quality standards
3. **SonarQube Job**: Performs static analysis
4. **Build Jobs**: Only run if quality gates pass

### Required GitHub Secrets

Add these secrets to your GitHub repository:

```
SONAR_TOKEN=your_sonarqube_token
SONAR_HOST_URL=your_sonarqube_url
```

### Workflow Behavior

- **Pull Requests**: Run quality checks and SonarQube analysis
- **Main Branch**: Full quality gates + build + deploy
- **Quality Failure**: Blocks deployment automatically

## 📈 Monitoring and Improvement

### Regular Quality Reviews

1. **Weekly**: Review SonarQube dashboard
2. **Monthly**: Analyze coverage trends
3. **Quarterly**: Update quality thresholds

### Quality Metrics Dashboard

Track these metrics over time:
- Overall coverage percentage
- Technical debt ratio
- Security hotspots count
- Code complexity trends
- Test execution time

### Continuous Improvement

1. **Increase Coverage**: Add tests for uncovered code
2. **Reduce Complexity**: Refactor complex functions
3. **Fix Technical Debt**: Address code smells regularly
4. **Security Hardening**: Review and fix security hotspots

## 🛠️ Troubleshooting

### Common Issues

1. **Coverage Not Generated**:
   ```bash
   # Ensure tests are running
   flutter test --coverage
   # Check for test failures
   flutter test --reporter=expanded
   ```

2. **SonarQube Connection Issues**:
   ```bash
   # Check if SonarQube is running
   curl http://localhost:9000/api/system/status
   # Restart SonarQube
   ./scripts/sonar_setup.sh stop
   ./scripts/sonar_setup.sh start
   ```

3. **Quality Gates Failing**:
   ```bash
   # Run individual checks
   flutter analyze
   flutter test
   ./scripts/coverage.sh
   ```

### Getting Help

- Check the logs in `coverage/` directory
- Review SonarQube project dashboard
- Run scripts with verbose output
- Check GitHub Actions logs for CI/CD issues

## 📚 Additional Resources

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Dart Analysis Options](https://dart.dev/guides/language/analysis-options)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
