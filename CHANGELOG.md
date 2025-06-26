# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-XX

### 🎉 Major Release: Gender-Inclusive Companion System

This major release transforms the app from a male-only experience to a fully gender-inclusive platform, allowing users to choose between Akhi (brother) or Ukhti (sister) companions.

### Added
- **Gender Selection Onboarding**: New final onboarding screen allowing users to choose their preferred companion type
- **Dynamic AI Personas**: AI system prompts now adapt based on user's gender selection
  - Akhi (brother) persona for users preferring male companion
  - Ukhti (sister) persona for users preferring female companion
- **Internationalization Support**: Added i18n infrastructure with English localization
- **Gender Settings Management**: Profile section in settings allowing users to change companion type
- **Smart Navigation**: Splash screen checks gender preference and routes accordingly
- **Comprehensive Testing**: Unit, widget, and integration tests for gender functionality

### Changed
- **App Branding**: Updated from "Akhi GPT" to "Companion GPT" for gender neutrality
- **System Prompts**: Completely refactored to be gender-aware with dynamic content
- **Chat Interface**: Headers and messages now reflect chosen companion type
- **Fallback Messages**: Error messages adapt to user's gender selection
- **Theme Names**: Updated theme naming for gender neutrality while maintaining backward compatibility

### Technical Improvements
- **Gender Utility Service**: Robust gender preference management with SharedPreferences
- **Dynamic Localization**: Gender-aware text generation using i18n tokens
- **State Management**: Proper gender state handling across app lifecycle
- **Error Handling**: Graceful fallbacks for gender preference loading

### Migration Notes
- Existing users will see the gender selection screen on first launch after update
- Default companion type is Akhi (brother) for backward compatibility
- All existing functionality remains unchanged, just with added gender awareness

### Testing
- Added comprehensive test suite covering:
  - Gender utility functions
  - System prompt generation
  - Widget behavior for gender selection
  - Integration tests for complete user flows
  - Settings page gender management

### Developer Experience
- Enhanced code organization with gender-aware services
- Improved type safety with UserGender enum
- Better separation of concerns for persona management
- Comprehensive documentation updates

---

## [1.x.x] - Previous Releases

Previous releases focused on core chat functionality, journal features, mood tracking, and privacy-first architecture. See git history for detailed changes in earlier versions.
