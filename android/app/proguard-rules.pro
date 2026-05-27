# Suppress warnings for missing classes (as recommended)
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.PaymentsClient
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.Wallet
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.WalletUtils
-dontwarn com.squareup.okhttp.CipherSuite
-dontwarn com.squareup.okhttp.ConnectionSpec
-dontwarn com.squareup.okhttp.TlsVersion
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Actually keep those classes to avoid runtime crash
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-keep class com.squareup.okhttp.** { *; }
-keep class proguard.annotation.** { *; }
-keep class com.razorpay.** { *; }

# Optional: Keep all model classes using Gson
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep all activities
-keep public class * extends android.app.Activity
