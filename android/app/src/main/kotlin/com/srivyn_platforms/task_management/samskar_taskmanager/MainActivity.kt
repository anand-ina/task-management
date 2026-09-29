package com.srivyn_platforms.task_management.samskar_taskmanager

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
