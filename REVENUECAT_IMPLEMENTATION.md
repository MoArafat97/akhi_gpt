# RevenueCat Subscription Implementation

This document outlines the complete RevenueCat subscription service implementation for the NafsAI Flutter app.

## 🎯 Overview

The implementation provides a comprehensive subscription system with:
- **Free Tier**: 75 messages/day, Simple Modern English only
- **Premium Tier**: 500 messages/day, all personality styles
- Secure API key management
- Message counting and limits
- Paywall integration
- Comprehensive error handling

## 📁 Files Added/Modified

### New Services
- `lib/services/subscription_service.dart` - Core subscription management
- `lib/services/message_counter_service.dart` - Daily message tracking
- `lib/services/secure_config_service.dart` - Secure API key handling

### New UI Components
- `lib/pages/paywall_screen.dart` - Subscription purchase screen
- `lib/widgets/subscription_status_widget.dart` - Settings subscription display

### Updated Files
- `lib/main.dart` - Service initialization
- `lib/pages/chat_screen.dart` - Message limit checks
- `lib/widgets/personality_settings_widget.dart` - Premium locks
- `lib/pages/settings_page.dart` - Subscription status
- `lib/utils/error_handler.dart` - Subscription error handling
- `pubspec.yaml` - RevenueCat dependency
- `.env` and `.env.example` - API key configuration

### Testing
- `test/subscription_service_test.dart` - Comprehensive service tests
- `test/paywall_screen_test.dart` - UI component tests

### CI/CD
- `.github/workflows/build-and-deploy.yml` - Automated builds with secrets

## 🔧 Setup Instructions

### 1. RevenueCat Configuration

1. **Create RevenueCat Account**: Sign up at [revenuecat.com](https://revenuecat.com)

2. **Configure Products**:
   - Create entitlement: `premium`
   - Add monthly and annual subscription products
   - Configure offerings

3. **Get API Keys**:
   - Android: Get Google Play API key
   - iOS: Get App Store API key

### 2. Environment Configuration

Update your `.env` file:

```env
# RevenueCat Configuration
REVENUECAT_API_KEY_ANDROID=your-android-api-key-here
REVENUECAT_API_KEY_IOS=your-ios-api-key-here
REVENUECAT_ENTITLEMENT_ID=premium
```

### 3. GitHub Secrets

Add these secrets to your GitHub repository:

```
REVENUECAT_API_KEY_ANDROID
REVENUECAT_API_KEY_IOS
REVENUECAT_ENTITLEMENT_ID
```

### 4. Platform Setup

#### Android
1. Add Google Play Billing permission to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

2. Configure ProGuard rules if using obfuscation

#### iOS
1. Enable In-App Purchase capability in Xcode
2. Configure App Store Connect with subscription products

## 🏗️ Architecture

### Subscription Tiers
```dart
enum SubscriptionTier {
  free,     // 75 messages/day, Simple Modern only
  premium;  // 500 messages/day, all personalities
}
```

### Message Flow
1. User attempts to send message
2. `MessageCounterService` checks daily limit
3. If limit reached and user is free tier → show paywall
4. If premium or under limit → allow message and increment counter

### Security Features
- API key obfuscation in logs
- Environment-based key validation
- Root/jailbreak detection (basic)
- Secure storage for subscription status

## 🎨 UI Components

### Paywall Screen
- Dynamic content based on source (messages/personality)
- Monthly/annual pricing options
- Purchase and restore functionality
- Error handling with user-friendly messages

### Settings Integration
- Subscription status display
- Usage statistics for free users
- Upgrade and restore buttons
- Premium feature indicators

### Personality Settings
- Lock icons on premium personalities
- Automatic paywall redirect for free users
- Clear premium requirements messaging

## 🧪 Testing

### Unit Tests
- Subscription service initialization
- Message counter logic
- Security configuration validation
- Error handling scenarios

### Integration Tests
- End-to-end subscription flow
- Message limit enforcement
- UI component interactions

### Manual Testing Checklist
- [ ] Free tier message limits work
- [ ] Premium personalities locked for free users
- [ ] Paywall displays correctly
- [ ] Purchase flow completes
- [ ] Restore purchases works
- [ ] Settings show correct status
- [ ] Error handling graceful

## 🔒 Security Considerations

### API Key Protection
- Keys stored in environment variables
- Obfuscated in logs and debug output
- Validated format and integrity
- Separate keys for dev/prod environments

### Purchase Validation
- Server-side receipt validation (recommended)
- Offline grace period for network issues
- Fraud detection through RevenueCat

### Data Privacy
- Minimal user data collection
- Local storage for usage statistics
- Secure transmission of purchase data

## 🚀 Deployment

### Development
1. Use test API keys from RevenueCat dashboard
2. Enable sandbox mode for testing
3. Test with sandbox Apple/Google accounts

### Production
1. Replace with production API keys
2. Enable obfuscation for release builds
3. Monitor subscription metrics
4. Set up webhooks for server notifications

## 📊 Monitoring

### Key Metrics
- Subscription conversion rate
- Daily active users by tier
- Message usage patterns
- Churn rate and retention

### Error Tracking
- Purchase failures
- API connectivity issues
- Subscription status sync problems

## 🔄 Maintenance

### Regular Tasks
- Monitor RevenueCat dashboard
- Update subscription pricing
- Review usage analytics
- Update API keys if needed

### Updates
- Keep RevenueCat SDK updated
- Monitor for breaking changes
- Test subscription flows after updates

## 🆘 Troubleshooting

### Common Issues

**Subscription not recognized**:
- Check API key configuration
- Verify entitlement ID matches
- Ensure proper initialization

**Purchase failures**:
- Check network connectivity
- Verify product configuration
- Review error logs

**Message limits not working**:
- Check SharedPreferences permissions
- Verify counter reset logic
- Review timezone handling

### Debug Commands
```bash
# Test subscription service
flutter test test/subscription_service_test.dart

# Check API configuration
flutter run --debug

# View logs
flutter logs
```

## 📞 Support

For implementation questions:
1. Check RevenueCat documentation
2. Review error logs in secure config service
3. Test with sandbox accounts first
4. Contact RevenueCat support for billing issues

---

**Implementation Status**: ✅ Complete
**Last Updated**: 2025-01-27
**Version**: 1.0.0
