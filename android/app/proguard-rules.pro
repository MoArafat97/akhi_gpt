# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Hive database rules
-keep class hive.** { *; }
-keep class * extends hive.HiveObject { *; }
-keepclassmembers class * extends hive.HiveObject {
    <fields>;
}

# Dio HTTP client rules
-keep class dio.** { *; }
-keepclassmembers class * {
    @retrofit2.http.* <methods>;
}

# Google Fonts rules
-keep class com.google.fonts.** { *; }

# Crypto rules for encryption
-keep class dart.crypto.** { *; }
-keep class crypto.** { *; }

# General rules to prevent issues with reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Play Feature Delivery library rules (replaces old Play Core)
# Required for Flutter's deferred components support and Android 14 compatibility
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Keep Play Feature Delivery classes
-keep class com.google.android.play.core.featuredelivery.** { *; }

# Google Play Services Tasks API (used by new Play libraries)
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep listeners and callbacks for deferred components
-keep class * implements com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }
-keep class * implements com.google.android.gms.tasks.OnSuccessListener { *; }
-keep class * implements com.google.android.gms.tasks.OnFailureListener { *; }
-keep class * implements com.google.android.play.core.tasks.OnSuccessListener { *; }
-keep class * implements com.google.android.play.core.tasks.OnFailureListener { *; }

# Prevent obfuscation of exception classes
-keep class com.google.android.play.core.splitinstall.SplitInstallException { *; }

# Keep request builders
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest$Builder { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest { *; }

# Suppress warnings for missing Play Core Tasks classes (replaced by Google Play Services Tasks)
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
