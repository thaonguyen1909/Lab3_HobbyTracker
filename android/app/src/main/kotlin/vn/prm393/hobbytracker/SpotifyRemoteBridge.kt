package vn.prm393.hobbytracker

import android.app.Activity
import android.content.pm.PackageManager
import com.spotify.android.appremote.api.ConnectionParams
import com.spotify.android.appremote.api.Connector
import com.spotify.android.appremote.api.SpotifyAppRemote
import com.spotify.protocol.client.Subscription
import com.spotify.protocol.types.PlayerState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Credentials never cross this bridge. App Remote owns the actual Spotify audio. */
class SpotifyRemoteBridge(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val methods = MethodChannel(messenger, "hobbytracker/spotify")
    private val events = EventChannel(messenger, "hobbytracker/spotify/events")
    private var sink: EventChannel.EventSink? = null
    private var remote: SpotifyAppRemote? = null
    private var subscription: Subscription<PlayerState>? = null
    private var owner: String? = null
    private var generation = 0
    private var pending: MethodChannel.Result? = null
    private var started = true
    init { methods.setMethodCallHandler(this); events.setStreamHandler(this) }
    fun onStart() { started = true }
    fun onStop() {
        started = false
        // Do not cancel the pending App Remote consent screen merely because it opened Spotify.
        if (remote != null) disconnect()
    }
    private fun installed(): Boolean = try {
        activity.packageManager.getPackageInfo("com.spotify.music", 0); true
    } catch (_: PackageManager.NameNotFoundException) { false }
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        emitConnection(remote?.isConnected == true)
    }
    override fun onCancel(arguments: Any?) { sink = null }
    private fun emitConnection(connected: Boolean) {
        sink?.success(mapOf("owner" to owner, "connected" to connected, "paused" to true))
    }
    private fun emitState(state: PlayerState) {
        sink?.success(mapOf("owner" to owner, "connected" to true, "paused" to state.isPaused,
            "track" to (state.track?.name ?: ""), "artist" to (state.track?.artist?.name ?: ""),
            "positionMs" to state.playbackPosition, "durationMs" to (state.track?.duration ?: 0L)))
    }
    private fun disconnect() {
        generation++
        pending?.error("cancelled", "Spotify connection was cancelled.", null); pending = null
        subscription?.cancel(); subscription = null
        remote?.let { SpotifyAppRemote.disconnect(it) }; remote = null
        emitConnection(false)
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "installed") { result.success(installed()); return }
        val uid = call.argument<String>("owner")
        if (uid.isNullOrBlank() || uid.length > 128 || uid.contains('/')) {
            result.error("unauthenticated", "Sign in again.", null); return
        }
        if (call.method == "disconnect") {
            if (owner == uid) { disconnect(); owner = null }
            result.success(null); return
        }
        if (call.method == "connect") {
            val clientId = call.argument<String>("clientId") ?: ""
            val redirect = call.argument<String>("redirectUri") ?: ""
            if (!Regex("[a-f0-9]{32}").matches(clientId) || redirect != "vn.prm393.hobbytracker://spotify-callback") {
                result.error("invalid-config", "Spotify configuration is unavailable.", null); return
            }
            if (!installed()) { result.error("not-installed", "Install Spotify first.", null); return }
            if (pending != null) { result.error("busy", "Spotify is already connecting.", null); return }
            if (owner == uid && remote?.isConnected == true) { result.success(null); return }
            disconnect(); owner = uid; val attempt = generation; pending = result
            val params = ConnectionParams.Builder(clientId).setRedirectUri(redirect)
                .showAuthView(call.argument<Boolean>("silent") != true).build()
            SpotifyAppRemote.connect(activity, params, object : Connector.ConnectionListener {
                override fun onConnected(appRemote: SpotifyAppRemote) {
                    if (attempt != generation || owner != uid || activity.isFinishing || activity.isDestroyed) {
                        SpotifyAppRemote.disconnect(appRemote); return
                    }
                    if (!started) {
                        SpotifyAppRemote.disconnect(appRemote)
                        pending?.error("background", "Return to the app and reconnect Spotify.", null); pending = null
                        return
                    }
                    remote = appRemote
                    val stream = appRemote.playerApi.subscribeToPlayerState(); subscription = stream
                    stream.setEventCallback { state -> if (attempt == generation && owner == uid) emitState(state) }
                    stream.setErrorCallback { if (attempt == generation && owner == uid) disconnect() }
                    pending?.success(null); pending = null
                }
                override fun onFailure(error: Throwable) {
                    if (attempt != generation || owner != uid) return
                    val code = if (error.javaClass.simpleName == "UserNotAuthorizedException") "not-authorized" else "connection-failed"
                    pending?.error(code, "Could not connect to Spotify.", null); pending = null
                    emitConnection(false)
                }
            })
            return
        }
        val player = remote
        if (owner != uid || player?.isConnected != true) {
            result.error("not-connected", "Reconnect Spotify to use playback controls.", null); return
        }
        val attempt = generation
        val operation = when (call.method) {
            "play" -> {
                val uri = call.argument<String>("uri") ?: ""
                if (!Regex("spotify:playlist:[A-Za-z0-9]{22}").matches(uri)) {
                    result.error("invalid-playlist", "Choose a Spotify playlist.", null); return
                }
                player.playerApi.play(uri)
            }
            "pause" -> player.playerApi.pause()
            "resume" -> player.playerApi.resume()
            "next" -> player.playerApi.skipNext()
            "previous" -> player.playerApi.skipPrevious()
            else -> { result.notImplemented(); return }
        }
        operation.setResultCallback {
            if (attempt == generation && owner == uid) result.success(null)
            else result.error("cancelled", "Spotify session changed.", null)
        }.setErrorCallback {
            result.error("control-failed", "Spotify could not perform this playback command.", null)
        }
    }
    fun dispose() {
        disconnect(); owner = null; sink = null
        methods.setMethodCallHandler(null); events.setStreamHandler(null)
    }
}
