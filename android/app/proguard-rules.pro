# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Mobile_scanner — keep Google ML Kit classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }

# Hive
-keep class * extends androidx.room.RoomDatabase
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin