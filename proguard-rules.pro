# Firebase Auth - Keep all classes and their members
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.auth.internal.** { *; }

# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Database
-keep class com.google.firebase.database.** { *; }

# Firebase App Check
-keep class com.google.firebase.appcheck.** { *; }

# Keep Firebase component registrar
-keep class * implements com.google.firebase.components.ComponentRegistrar

# Keep all Firebase receivers and services
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service

# Google Play Services
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.ads.identifier.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}