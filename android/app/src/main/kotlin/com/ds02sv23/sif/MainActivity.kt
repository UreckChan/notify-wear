package com.ds02sv23.sif

import io.flutter.embedding.android.FlutterActivity

import android.os.Bundle
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", "transparent")
        super.onCreate(savedInstanceState)
    }
}
