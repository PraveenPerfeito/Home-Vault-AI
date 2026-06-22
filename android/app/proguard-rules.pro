# Flutter — keep reflection-based classes intact.
-keep class io.flutter.** { *; }

# Firebase — keep all Firebase SDK classes.
-keep class com.google.firebase.** { *; }

# Google ML Kit — text recognition model classes.
-keep class com.google.mlkit.** { *; }

# Google Play Services — required by Firebase Auth and Google Sign-In.
-keep class com.google.android.gms.** { *; }

# flutter_local_notifications — R8 strips plugin + Gson serializers; keep entire package.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.styles.** { *; }

# Gson — required by flutter_local_notifications for NotificationDetails serialization.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# image_picker — FileProvider for camera capture.
-keep class androidx.core.content.FileProvider { *; }

# Kotlin coroutines — keep internal dispatcher classes.
-keep class kotlinx.coroutines.** { *; }

# Hive — no generated adapters yet; keep when TypeAdapters are added.
# -keep class * extends com.google.gson.TypeAdapter

# Suppress warnings for missing library classes not used at runtime.
-dontwarn com.google.android.gms.**
-dontwarn io.flutter.**

# ML Kit optional language packs — not bundled (Latin-only OCR).
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
