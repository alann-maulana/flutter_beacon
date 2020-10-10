@file:Suppress("DEPRECATION") // Plugin registry is but RequestPermissionsResultListener is not
package com.flutterbeacon

import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

object PermissionController : PluginRegistry.RequestPermissionsResultListener {
    private var looping = false
    private val listeners = mutableSetOf<PluginRegistry.RequestPermissionsResultListener>()
    private val toRemoveListeners = mutableSetOf<PluginRegistry.RequestPermissionsResultListener>()

    fun register(listener: PluginRegistry.RequestPermissionsResultListener) = listeners.add(listener)

    fun unregister(listener: PluginRegistry.RequestPermissionsResultListener) {
        if(!looping) {
            listeners.remove(listener)
        } else {
            toRemoveListeners.add(listener)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        looping = true
        val result = listeners.filter { it !in toRemoveListeners }.any { it.onRequestPermissionsResult(requestCode, permissions, grantResults) }
        toRemoveListeners.forEach { listeners.remove(it) }
        looping = false
        return result
    }

}

sealed class PermissionResultListener(private val plugin: FlutterBeaconPlugin) : PluginRegistry.RequestPermissionsResultListener {
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

    protected fun unregister(): Unit? = PermissionController.unregister(this)
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
        PermissionController.register(this)
    }

    override fun onCancel(arguments: Any?) {
        unregister()
    }
}
