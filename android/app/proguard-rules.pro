# Flutter's own classes are kept by the engine's consumer rules; these cover
# the plugins this app depends on.

# flutter_secure_storage relies on the AndroidX security library.
-keep class androidx.security.crypto.** { *; }

# Keep annotations used for reflection by the Play Core / Flutter deferred
# components stubs that R8 sees on the classpath.
-dontwarn com.google.android.play.core.**
