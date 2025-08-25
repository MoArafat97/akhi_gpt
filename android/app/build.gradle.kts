import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = file("../key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.moarafat.akhi_gpt"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "33.0.2"
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = false
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        freeCompilerArgs += listOf(
            "-opt-in=kotlin.RequiresOptIn",
            "-Xjvm-default=all"
        )
    }

    // Build performance optimizations
    buildFeatures {
        buildConfig = false
        resValues = false
    }

    // Packaging options to reduce APK size and build time
    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.moarafat.akhi_gpt"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Required for Isar database and fragment shaders
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val alias = System.getenv("ANDROID_KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            val keyPass = System.getenv("ANDROID_KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
            val storePass = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: "keystore.jks"

            // Ensure we have all required values including alias
            if (alias != null && keyPass != null && storePass != null) {
                keyAlias = alias
                keyPassword = keyPass
                storePassword = storePass
                storeFile = file(storeFilePath)
            } else {
                throw GradleException("Missing signing configuration. Please set environment variables or create key.properties file with keyAlias, keyPassword and storePassword.")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            // Disable minification and shrinking for faster debug builds
            isMinifyEnabled = false
            isShrinkResources = false
            // Disable crashlytics for debug builds to speed up compilation
            manifestPlaceholders["crashlyticsCollectionEnabled"] = false
            // Enable multidex for debug builds if needed
            multiDexEnabled = true
        }
    }
}

// Helper function to check if keystore and required environment variables exist
fun hasKeystoreAndEnvVars(): Boolean {
    val keystoreExists = file("keystore.jks").exists() ||
                        file("nafs_ai_keystore.jks").exists() ||
                        file("upload-keystore.jks").exists()

    val envVarsExist = !System.getenv("ANDROID_KEY_ALIAS").isNullOrEmpty() &&
                      !System.getenv("ANDROID_KEY_PASSWORD").isNullOrEmpty() &&
                      !System.getenv("ANDROID_KEYSTORE_PASSWORD").isNullOrEmpty()

    return keystoreExists && envVarsExist
}

flutter {
    source = "../.."
}

dependencies {
    // Play Feature Delivery library - required for Flutter's deferred components support
    // This replaces the old Play Core library and is compatible with Android 14 (targetSdkVersion 34)
    // See: https://developer.android.com/guide/playcore/migration
    implementation("com.google.android.play:feature-delivery:2.1.0")
    implementation("com.google.android.play:feature-delivery-ktx:2.1.0")

    // Google Play Services Tasks - required for Play Core Tasks API compatibility
    implementation("com.google.android.gms:play-services-tasks:18.2.0")
}
