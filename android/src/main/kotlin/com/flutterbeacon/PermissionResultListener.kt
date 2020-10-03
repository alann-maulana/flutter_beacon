package com.flutterbeacon

import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

sealed class PermissionResultListener(protected val plugin: FlutterBeaconPlugin) : PluginRegistry.RequestPermissionsResultListener {
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != FlutterBeaconPlugin.REQUEST_CODE_LOCATION) return false
        val permission = permissions.first()
        val result = if (!ActivityCompat.shouldShowRequestPermissionRationale(plugin.activity!!.activity, permission)) {
            if (grantResults.isEmpty()) {
                "NOT_DETERMINED"
            } else {
                if (grantResults.first() == PackageManager.PERMISSION_GRANTED) {
                    "GRANTED"
                } else {
                    "DENIED"
                }
            }
        } else {
            "DENIED"
        }
        onResult(result)
        return true
    }

    abstract fun onResult(result: String)

    protected fun unregister(): Unit? = plugin.activity?.removeRequestPermissionsResultListener(this)
}

class PermissionResponder(private val result: MethodChannel.Result, plugin: FlutterBeaconPlugin) : PermissionResultListener(plugin) {
    override fun onResult(result: String) {
        if (result == "GRANTED") {
            this.result.success(true)
        } else {
            this.result.error("Beacon", "location services not allowed", null)
        }

        unregister()
    }
}

class PermissionBroadCaster(plugin: FlutterBeaconPlugin) : PermissionResultListener(plugin), EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    override fun onResult(result: String) {
        sink?.success(result)
    }

    override fun onListen(arguments: Any, events: EventChannel.EventSink) {
        sink = events
        plugin.activity?.addRequestPermissionsResultListener(this)
    }

    override fun onCancel(arguments: Any?) {
        unregister()
    }
}
