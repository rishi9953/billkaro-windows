# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Suppress warnings for WebView
-dontwarn android.webkit.**
-dontwarn com.google.android.gms.clearcut_client.**

# Suppress warnings for hidden APIs (debug builds)
-dontwarn dalvik.system.VMStack

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep WorkManager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Keep Gson classes
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Suppress warnings for userfaultfd (kernel-level, harmless)
-dontwarn **userfaultfd**

# Keep Google Play Core classes (required for deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter deferred component classes
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep Play Store Deferred Component Manager
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

# Keep Google ML Kit classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep ML Kit text recognition
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**

# Keep ML Kit image labeling
-keep class com.google.android.gms.internal.mlkit_vision_label_common.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_label_common.**

# Keep ML Kit commons
-keep class com.google.mlkit.common.** { *; }
-dontwarn com.google.mlkit.common.**

# Keep all model classes
-keep class * extends com.google.mlkit.common.model.** { *; }

# Keep InputImage and related classes
-keep class com.google.mlkit.vision.common.** { *; }
-dontwarn com.google.mlkit.vision.common.**
