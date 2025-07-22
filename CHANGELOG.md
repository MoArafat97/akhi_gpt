# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-01-XX

### 🎯 Application Rebranding: Complete Rename to NafsAI

This release completes the application rebranding from "Akhi GPT" to "NafsAI" based on user feedback requesting proper app naming.

#### Changed
- **Application Name**: Complete rename from "Akhi GPT" to "NafsAI" across all platforms
- **Package Identifiers**: Updated all bundle identifiers from `com.moarafat.akhi_gpt` to `com.moarafat.nafs_ai`
- **Display Names**: Updated user-facing app names on all platforms (Android, iOS, web, desktop)
- **Project Structure**: Updated project names and binary names across all platform configurations
- **Documentation**: Updated all documentation, README, and configuration files
- **Build Configuration**: Updated CI/CD workflows and build scripts for new naming

#### Technical Details
- Android: Updated namespace, applicationId, and package structure
- iOS: Updated CFBundleDisplayName, CFBundleName, and PRODUCT_BUNDLE_IDENTIFIER
- Web: Updated manifest.json and index.html with new app name
- Desktop: Updated CMakeLists.txt for Linux, Windows, and macOS
- Proxy: Updated HTTP headers and referer information

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
- **App Branding**: Updated from "Akhi GPT" to "NafsAI" for gender neutrality
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

### Developer Experience
- Enhanced code organization with gender-aware services
- Improved type safety with UserGender enum
- Better separation of concerns for persona management
- Comprehensive documentation updates

---

## [1.x.x] - Previous Releases

Previous releases focused on core chat functionality, journal features, mood tracking, and privacy-first architecture. See git history for detailed changes in earlier versions.
