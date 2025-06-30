# Quick Setup Guide for Diagnostic Solution

## 🚀 Implementation Steps

### 1. Verify Files Are Added
Ensure these new files exist in your project:
```
lib/services/diagnostic_service.dart
lib/pages/diagnostic_page.dart
lib/utils/config_validator.dart
lib/utils/error_handler.dart
test/openrouter_service_test.dart
```

### 2. Update Dependencies (if needed)
Add to `pubspec.yaml` if not already present:
```yaml
dependencies:
  dio: ^5.3.2
  flutter_dotenv: ^5.1.0
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  mockito: ^5.4.2
  build_runner: ^2.4.7
```

### 3. Generate Mock Files for Testing
Run this command to generate test mocks:
```bash
flutter packages pub run build_runner build
```

### 4. Verify .env Configuration
Ensure your `.env` file has the correct format:
```env
# OpenRouter API Configuration
OPENROUTER_API_KEY=sk-or-v1-your-actual-key-here
DEFAULT_MODEL=qwen/qwen3-32b:free
FALLBACK_MODELS=qwen/qwq-32b:free,qwen/qwen3-235b-a22b:free

# Proxy Configuration (optional)
ENABLE_PROXY=false
PROXY_ENDPOINT=http://localhost:8080
```

### 5. Test the Implementation
1. **Run the app**: `flutter run`
2. **Navigate to Settings** → Developer → API Diagnostics
3. **Run Full Diagnostics** to test all components
4. **Check logs** in your development console

### 6. Run Unit Tests
```bash
# Run all tests
flutter test

# Run specific diagnostic tests
flutter test test/openrouter_service_test.dart
```

## 🔍 Quick Validation Checklist

### ✅ Configuration Check
- [ ] .env file exists and is loaded
- [ ] API key starts with `sk-or-v1-`
- [ ] Models are in `provider/model-name` format
- [ ] No duplicate models in fallback list

### ✅ Functionality Check
- [ ] Diagnostic page opens without errors
- [ ] "Run Full Diagnostics" completes successfully
- [ ] "Test Connection" shows appropriate result
- [ ] "Test All Models" validates each model
- [ ] "Copy Report" works correctly

### ✅ Error Handling Check
- [ ] Invalid API key shows clear error message
- [ ] Network issues trigger appropriate fallbacks
- [ ] Rate limiting is handled gracefully
- [ ] Model unavailability switches to fallback

## 🐛 Common Setup Issues

### Issue: Import Errors
**Problem**: Cannot import diagnostic services
**Solution**: Ensure all files are in correct directories and run `flutter clean && flutter pub get`

### Issue: Mock Generation Fails
**Problem**: Test mocks not generated
**Solution**: 
```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Issue: .env Not Loading
**Problem**: Environment variables not found
**Solution**: 
1. Verify .env file is in project root
2. Check main.dart loads dotenv correctly
3. Ensure .env is not in .gitignore (for local testing)

### Issue: Diagnostic Page Crashes
**Problem**: UI errors when opening diagnostics
**Solution**:
1. Check all imports are correct
2. Verify Flutter version compatibility
3. Run `flutter doctor` to check setup

## 📱 Testing on Different Platforms

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Web (for testing)
```bash
flutter run -d web
```

## 🔧 Customization Options

### Adding Custom Diagnostic Checks
1. Extend `DiagnosticService` class
2. Add new check methods
3. Update `DiagnosticReport` class
4. Modify UI to display new results

### Modifying Error Messages
1. Edit `ErrorHandler.analyzeError()` method
2. Update error categories in `ErrorCategory` enum
3. Customize user messages for specific errors

### Changing Log Levels
1. Modify log statements in services
2. Update `ErrorHandler.logError()` method
3. Adjust log filtering in development console

## 📊 Monitoring Setup

### Development Monitoring
- Use Flutter DevTools for real-time debugging
- Monitor console logs for diagnostic messages
- Check network tab for API call details

### Production Monitoring (Future)
- Implement crash reporting (Firebase Crashlytics)
- Add performance monitoring
- Set up error tracking and alerting

## 🎯 Success Criteria

Your diagnostic solution is working correctly when:

1. **Configuration Validation**: ✅ All environment checks pass
2. **API Connectivity**: ✅ Connection tests succeed
3. **Model Testing**: ✅ At least one model is available
4. **Error Handling**: ✅ Graceful fallbacks work
5. **User Experience**: ✅ Clear error messages displayed
6. **Logging**: ✅ Detailed logs help with debugging

## 🚨 Troubleshooting Commands

### Reset Configuration
```bash
# Clear Flutter cache
flutter clean
flutter pub get

# Reset secure storage (if needed)
# This will clear saved API states
```

### Debug Mode
```bash
# Run with verbose logging
flutter run --verbose

# Run specific test with details
flutter test --verbose test/openrouter_service_test.dart
```

### Check Dependencies
```bash
# Verify all packages are compatible
flutter pub deps
flutter doctor
```

## 📞 Next Steps

After successful setup:

1. **Monitor Performance**: Track API response times and error rates
2. **Gather Feedback**: Use diagnostic reports to identify common issues
3. **Iterate Improvements**: Enhance error messages and fallback logic
4. **Document Issues**: Keep track of resolved problems for future reference

## 🎉 Completion

Once you see ✅ for all diagnostic checks, your chat functionality should be working reliably with proper error handling and fallback mechanisms in place!

For detailed usage instructions, see `DIAGNOSTIC_SOLUTION.md`.
