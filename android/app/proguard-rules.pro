# Proguard / R8 rules for release builds.
# Most Flutter plugins ship their own consumer-rules.pro which are picked up
# automatically. The rules below cover the engine and a few plugins that use
# reflection or need their entry points preserved.

# --- Flutter engine ----------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-dontwarn io.flutter.embedding.**

# --- just_audio: ExoPlayer / Media3 -----------------------------------------
# just_audio relies on ExoPlayer; some internal classes are touched reflectively.
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.ryanheise.just_audio.** { *; }

# --- record (audio recording) ------------------------------------------------
-keep class com.llfbandit.record.** { *; }

# --- flutter_local_notifications -------------------------------------------
# Boot-time + scheduled receivers must be reachable by name.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# --- timezone / flutter_timezone --------------------------------------------
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.bp.**

# --- General safety: keep names of classes accessed by reflection -----------
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*
-keepclassmembers class * {
    @kotlin.Metadata <fields>;
}

# Keep Parcelable creators (Flutter platform channels sometimes pass these).
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
