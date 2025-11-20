# FoodFlow ProGuard Rules

# ================================
# Flutter
# ================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# ================================
# Firebase
# ================================
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class com.google.firebase.firestore.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keepclassmembers class com.google.firebase.auth.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keepclassmembers class com.google.firebase.messaging.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# ================================
# Google Play Services
# ================================
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

# ================================
# Kotlin
# ================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ================================
# Gson (если используется)
# ================================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ================================
# OkHttp / Retrofit (если используется)
# ================================
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-dontwarn org.codehaus.mojo.animal_sniffer.*
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# ================================
# WebView
# ================================
-keepclassmembers class fqcn.of.javascript.interface.for.webview {
   public *;
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, jav.lang.String);
}

# ================================
# SQLite / Hive
# ================================
-keep class * extends com.hivedb.** { *; }
-keep class * implements com.hivedb.** { *; }

# ================================
# Image Picker / Camera
# ================================
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.camera.** { *; }

# ================================
# Local Auth / Biometrics
# ================================
-keep class io.flutter.plugins.localauth.** { *; }

# ================================
# URL Launcher
# ================================
-keep class io.flutter.plugins.urllauncher.** { *; }

# ================================
# Connectivity Plus
# ================================
-keep class io.flutter.plugins.connectivity.** { *; }

# ================================
# Path Provider
# ================================
-keep class io.flutter.plugins.pathprovider.** { *; }

# ================================
# Shared Preferences
# ================================
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ================================
# Package Info
# ================================
-keep class io.flutter.plugins.packageinfo.** { *; }

# ================================
# Permission Handler
# ================================
-keep class com.baseflow.permissionhandler.** { *; }

# ================================
# Geolocator
# ================================
-keep class com.baseflow.geolocator.** { *; }

# ================================
# Google Maps Flutter
# ================================
-keep class io.flutter.plugins.googlemaps.** { *; }

# ================================
# Mobile Scanner (QR)
# ================================
-keep class dev.steenbakker.mobile_scanner.** { *; }

# ================================
# Общие правила
# ================================
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Сохранить нативные методы
-keepclasseswithmembernames class * {
    native <methods>;
}

# Сохранить enum
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Сохранить Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Сохранить Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Сохранить R классы
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ================================
# Удалить логи в production
# ================================
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# ================================
# Оптимизация
# ================================
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
-repackageclasses ''