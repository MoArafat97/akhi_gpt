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
