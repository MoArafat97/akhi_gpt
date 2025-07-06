# OpenRouter API Key Migration Guide

This guide explains the migration from hardcoded OpenRouter API keys to user-managed API keys and model selection.

## 🔄 What Changed

### Before (Fixed Configuration)
- API key was hardcoded in `.env` file
- Models were fixed in environment variables
- Users had no control over costs or model selection
- App developer paid for all API usage

### After (User-Managed Configuration)
- Users provide their own OpenRouter API keys
- Users can select from 400+ available models
- Users control their own costs and usage
- Full transparency and user control

## 🚀 New Features

### 1. User API Key Management
- Secure storage using `flutter_secure_storage`
- API key validation with OpenRouter's API
- Clear setup instructions and error messages
- Easy key management in settings

### 2. Dynamic Model Selection
- Fetch available models from OpenRouter API
- Filter by free/paid models
- Display model information (pricing, context length, capabilities)
- Cache models locally for performance

### 3. Setup Flow
- Guided setup for new users
- API key validation during setup
- Model selection interface
- Integration with existing onboarding

### 4. Enhanced Settings
- New "OpenRouter Configuration" section
- API key management interface
- Model selection widget
- Status indicators and validation

## 📱 User Experience

### For New Users
1. Complete existing onboarding flow
2. Guided through API key setup
3. Choose their preferred AI model
4. Start chatting with full control

### For Existing Users
1. App detects missing user API key
2. Redirected to setup flow
3. Can continue using app after setup
4. Backward compatibility maintained

## 🔧 Technical Implementation

### New Services
- `UserApiKeyService`: Manages user's API keys securely
- `ModelManagementService`: Handles model fetching and caching

### Updated Services
- `OpenRouterService`: Now uses user API keys and selected models
- Enhanced error handling and fallback logic

### New UI Components
- `ApiKeySettingsWidget`: API key management interface
- `ModelSelectionWidget`: Model selection with search and filtering
- `OpenRouterSetupPage`: Guided setup flow

### Database Changes
- User API keys stored in secure storage
- Selected models stored in SharedPreferences
- Model cache for performance

## 🔒 Security Considerations

### API Key Security
- Stored using `flutter_secure_storage`
- Never logged or exposed in debug output
- Validated before storage
- Can be cleared/updated by user

### Data Privacy
- No API keys sent to app servers
- Direct communication with OpenRouter
- User controls their own data

## 🧪 Testing

### Manual Testing
1. Fresh install - should show setup flow
2. API key validation - test invalid keys
3. Model selection - verify filtering works
4. Chat functionality - test with user's key
5. Settings - verify key management works

### Automated Testing
- Unit tests for new services
- Widget tests for new components
- Integration tests for setup flow

## 🚨 Migration Steps for Developers

### 1. Environment Cleanup
```bash
# Remove hardcoded API key from .env (keep for backward compatibility during transition)
# OPENROUTER_API_KEY=your-key-here  # Comment out or remove

# Update build scripts to not require API key
```

### 2. Update Documentation
- Update README with new setup instructions
- Add API key acquisition guide
- Update troubleshooting section

### 3. User Communication
- Notify users about the change
- Provide clear migration instructions
- Offer support during transition

## 📋 Backward Compatibility

### Transition Period
- App still checks for environment API key as fallback
- Existing functionality preserved
- Gradual migration approach

### Legacy Support
- Old configuration still works temporarily
- Users can migrate at their own pace
- No forced updates required

## 🔍 Troubleshooting

### Common Issues

#### "Service not configured" Error
- **Cause**: User hasn't set up API key
- **Solution**: Go to Settings → OpenRouter Configuration

#### "Invalid API key" Error
- **Cause**: Incorrect or expired API key
- **Solution**: Verify key format (starts with `sk-or-v1-`)

#### "No models available" Error
- **Cause**: API key lacks permissions or network issue
- **Solution**: Check API key permissions and internet connection

#### Models not loading
- **Cause**: Network issues or API rate limits
- **Solution**: Try refreshing or check OpenRouter status

### Debug Steps
1. Check API key format and validity
2. Verify internet connection
3. Test with different models
4. Check OpenRouter service status
5. Clear app cache if needed

## 📞 Support

### For Users
- In-app help and setup guides
- Clear error messages with solutions
- Link to OpenRouter documentation

### For Developers
- Comprehensive logging for debugging
- Error tracking and reporting
- Performance monitoring

## 🎯 Benefits

### For Users
- **Control**: Full control over AI model and costs
- **Privacy**: Direct communication with OpenRouter
- **Choice**: Access to 400+ AI models
- **Transparency**: Clear pricing and usage information

### For Developers
- **Scalability**: No API cost burden
- **Flexibility**: Users can choose models that suit their needs
- **Sustainability**: Sustainable business model
- **Focus**: Focus on app features, not API costs

## 🔮 Future Enhancements

### Planned Features
- Model performance analytics
- Usage tracking and budgeting
- Model recommendations based on usage
- Advanced filtering and sorting options
- Bulk model testing capabilities

### Potential Integrations
- Multiple API provider support
- Custom model endpoints
- Local model support
- Advanced prompt engineering tools

---

This migration represents a significant improvement in user control, privacy, and app sustainability while maintaining the core functionality that users love.
