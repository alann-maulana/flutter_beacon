package com.flutterbeacon

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class EnableBluetoothListener(private val binding: ActivityPluginBinding, private val result: MethodChannel.Result) : PluginRegistry.ActivityResultListener {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != FlutterBeaconPlugin.REQUEST_CODE_BLUETOOTH) return false
        if (resultCode == Activity.RESULT_OK) {
            result.success(true)
        } else {
            result.error("Beacon", "bluetooth disabled", null)
        }

        binding.removeActivityResultListener(this)
        return true
    }
}
