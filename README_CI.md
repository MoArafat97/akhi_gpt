# 🚀 CI/CD Pipeline for Akhi GPT Android

This document explains how to use the automated CI/CD pipeline for deploying the Akhi GPT Flutter app to the Google Play Store.

## 📋 Overview

The pipeline consists of three main workflows:

1. **🧪 Pull Request Testing** - Runs linting and tests on all PRs
2. **🏗️ Staging Builds** - Builds staging AAB files when pushing to `develop` branch
3. **🚀 Production Deployment** - Deploys signed releases to Google Play when pushing tags to `main`

## 🔧 Required GitHub Secrets

### Production Environment Secrets

The following secrets must be configured in your GitHub repository under **Settings → Environments → production**:

| Secret Name | Description | Format |
|-------------|-------------|---------|
| `GOOGLE_PLAY_JSON_KEY` | Google Play Console service account key | Base64-encoded JSON |
| `ANDROID_KEYSTORE_FILE` | Android signing keystore | Base64-encoded .jks file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Plain text |
| `ANDROID_KEY_ALIAS` | Key alias (e.g., `akhi_gpt_release`) | Plain text |
| `ANDROID_KEY_PASSWORD` | Key password | Plain text |

### Staging Environment Secrets

For staging builds, only the Google Play key is required:

| Secret Name | Description | Format |
|-------------|-------------|---------|
| `GOOGLE_PLAY_JSON_KEY` | Google Play Console service account key | Base64-encoded JSON |

## 🔐 Setting Up Secrets

### 1. Encode Your Keystore File

```bash
# Convert your keystore to base64
base64 -i path/to/your/keystore.jks | pbcopy  # macOS
base64 -w 0 path/to/your/keystore.jks         # Linux
```

### 2. Encode Your Google Play JSON Key

```bash
# Convert your Google Play service account JSON to base64
base64 -i path/to/google-play-key.json | pbcopy  # macOS
base64 -w 0 path/to/google-play-key.json         # Linux
```

### 3. Add Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings → Environments**
3. Select **production** environment
4. Click **Add secret** and add each secret with its corresponding value

## 🚀 Deployment Workflows

### Pull Request Testing

**Trigger:** Opening or updating a pull request to `master` or `develop`

**What it does:**
- ✅ Runs `flutter analyze --fatal-infos`
- ✅ Runs `flutter test --coverage`
- ✅ Uploads test coverage to Codecov

**No manual action required** - runs automatically on all PRs.

### Staging Deployment

**Trigger:** Pushing to `develop` branch

**What it does:**
- 🏗️ Builds unsigned AAB file using Fastlane
- 📤 Uploads AAB as GitHub artifact (30-day retention)
- 🔄 Optionally uploads to Google Play Internal Testing (currently disabled)

**How to trigger:**
```bash
git checkout develop
git merge feature/your-feature
git push origin develop
```

### Production Deployment

**Trigger:** Pushing a version tag to `master` branch

**What it does:**
- 🔐 Decodes and sets up signing keystore
- 🏗️ Builds signed release AAB
- 🚀 Uploads to Google Play Production track as **draft**
- 📤 Uploads signed AAB as GitHub artifact (90-day retention)
- 🧹 Cleans up sensitive files

**How to trigger:**
```bash
# 1. Update version in pubspec.yaml
# version: 1.2.0+3

# 2. Commit and push to master
git checkout master
git add pubspec.yaml
git commit -m "chore: bump version to 1.2.0+3"
git push origin master

# 3. Create and push version tag
git tag v1.2.0
git push origin v1.2.0
```

## 📱 Google Play Console

After a successful production deployment:

1. 🔗 Visit [Google Play Console](https://play.google.com/console)
2. 📱 Navigate to your app
3. 🔍 Go to **Release → Production**
4. 📋 Review the draft release
5. ✅ Click **Review release** → **Start rollout to production**

## 🛠️ Fastlane Configuration

The pipeline uses Fastlane with two main lanes:

### `deploy_staging`
- Builds unsigned AAB for testing
- Can optionally upload to Internal Testing track

### `deploy_production`
- Builds signed AAB with proper versioning
- Uploads to Production track as draft
- Includes comprehensive error handling

## 🔍 Troubleshooting

### Common Issues

**❌ "Missing required environment variables"**
- Ensure all secrets are properly set in GitHub Environments
- Check that secret names match exactly (case-sensitive)

**❌ "Keystore not found"**
- Verify `ANDROID_KEYSTORE_FILE` is properly base64-encoded
- Ensure the keystore file is valid and not corrupted

**❌ "Google Play API authentication failed"**
- Check that `GOOGLE_PLAY_JSON_KEY` is correctly base64-encoded
- Verify the service account has proper permissions in Google Play Console

**❌ "Flutter build failed"**
- Check that all dependencies are properly declared in `pubspec.yaml`
- Ensure the code passes `flutter analyze` and `flutter test` locally

### Debug Steps

1. **Check workflow logs** in GitHub Actions tab
2. **Verify secrets** are set correctly in repository settings
3. **Test locally** by running the same Flutter commands
4. **Validate keystore** by testing signing locally

## 📊 Monitoring

- **GitHub Actions** - View build status and logs
- **Codecov** - Monitor test coverage trends
- **Google Play Console** - Track app releases and user feedback
- **GitHub Releases** - Automatic release notes from tags

## 🔄 Version Management

The pipeline automatically extracts version information from `pubspec.yaml`:

```yaml
version: 1.2.0+3
#        ^     ^
#        |     └── Build number (versionCode)
#        └──────── Version name (versionName)
```

**Important:** Always update both version name and build number before creating a release tag.

## 🎯 Best Practices

1. **🔀 Use feature branches** and create PRs for all changes
2. **✅ Ensure tests pass** before merging to `develop`
3. **📝 Update version** in `pubspec.yaml` before tagging releases
4. **🏷️ Use semantic versioning** for tags (e.g., `v1.2.0`)
5. **📋 Review releases** in Google Play Console before publishing
6. **🔐 Keep secrets secure** and rotate them periodically
7. **📊 Monitor coverage** and maintain good test coverage

---

For questions or issues with the CI/CD pipeline, please create an issue in this repository.
