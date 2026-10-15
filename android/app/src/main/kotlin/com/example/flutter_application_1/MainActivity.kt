package com.example.flutter_application_1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var storySounds: StorySoundPlayer? = null
    private var soundChannel: MethodChannel? = null
    private var recordedVoice: RecordedVoicePlayer? = null
    private var voiceChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        storySounds = StorySoundPlayer(this)
        soundChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kkoma/sound_effects")
        soundChannel?.setMethodCallHandler { call, result -> storySounds?.handle(call, result) }
        recordedVoice = RecordedVoicePlayer(this)
        voiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kkoma/recorded_voice")
        voiceChannel?.setMethodCallHandler { call, result -> recordedVoice?.handle(call, result) }
    }

    override fun onPause() {
        storySounds?.setActive(false)
        recordedVoice?.setActive(false)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        storySounds?.setActive(true)
        recordedVoice?.setActive(true)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        soundChannel?.setMethodCallHandler(null)
        voiceChannel?.setMethodCallHandler(null)
        recordedVoice?.release()
        recordedVoice = null
        storySounds?.release()
        storySounds = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
