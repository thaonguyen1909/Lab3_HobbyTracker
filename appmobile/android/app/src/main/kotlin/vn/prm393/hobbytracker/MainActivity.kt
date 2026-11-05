package vn.prm393.hobbytracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var spotify: SpotifyRemoteBridge? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        spotify = SpotifyRemoteBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
    override fun onStart() { super.onStart(); spotify?.onStart() }
    override fun onStop() { spotify?.onStop(); super.onStop() }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        spotify?.dispose(); spotify = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
