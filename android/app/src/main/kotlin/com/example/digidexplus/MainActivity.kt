package com.example.digidexplus

import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The card sounds play on the media volume; without this the volume
        // keys change the ringtone while nothing is playing.
        volumeControlStream = AudioManager.STREAM_MUSIC
    }
}
