# App Remote 0.8.0 ships Gson and optional Jackson mapper bytecode.
# This app uses Gson; these optional Jackson bases and compile-time annotation
# are the only missing classes reported by R8 for this build.
# Keep all other missing-class diagnostics enabled.
-dontwarn com.fasterxml.jackson.databind.deser.std.StdDeserializer
-dontwarn com.fasterxml.jackson.databind.ser.std.StdSerializer
-dontwarn com.spotify.base.annotations.NotNull

# Firebase discovers registrars by class name from AndroidManifest metadata and
# calls their no-arg constructors reflectively. Keep that reflective entry point
# in R8 full mode; otherwise startup reports NoSuchMethodException for registrars.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
