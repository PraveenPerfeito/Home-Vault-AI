# Flutter — keep reflection-based classes intact.
-keep class io.flutter.** { *; }

# Firebase — keep all Firebase SDK classes.
-keep class com.google.firebase.** { *; }

# Google ML Kit — text recognition model classes.
-keep class com.google.mlkit.** { *; }

# Google Play Services — required by Firebase Auth and Google Sign-In.
-keep class com.google.android.gms.** { *; }

# image_picker — FileProvider for camera capture.
-keep class androidx.core.content.FileProvider { *; }

# Kotlin coroutines — keep internal dispatcher classes.
-keep class kotlinx.coroutines.** { *; }

# Hive — no generated adapters yet; keep when TypeAdapters are added.
# -keep class * extends com.google.gson.TypeAdapter

# Suppress warnings for missing library classes not used at runtime.
-dontwarn com.google.android.gms.**
-dontwarn io.flutter.**
