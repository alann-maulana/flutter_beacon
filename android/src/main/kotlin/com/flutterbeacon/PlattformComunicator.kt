package com.flutterbeacon

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.flutterbeacon.FlutterBeaconPlugin.Companion.REQUEST_CODE_LOCATION
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


@RequiresApi(Build.VERSION_CODES.M)
class PlattformComunicator(private val plugin: FlutterBeaconPlugin) : MethodChannel.MethodCallHandler {
    private lateinit var beaconController: BeaconController
    private var activityBinding: ActivityPluginBinding? = null
    private var channel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventChannelMonitoring: EventChannel? = null
    private var eventChannelBluetoothState: EventChannel? = null
    private var eventChannelAuthorizationStatus: EventChannel? = null

    @Suppress("ReplaceNotNullAssertionWithElvisReturn")
    fun init(binaryMessenger: BinaryMessenger, activity: ActivityPluginBinding) {
        beaconController = BeaconController(plugin, activity.activity)
        channel = MethodChannel(binaryMessenger, "flutter_beacon")
        channel!!.setMethodCallHandler(this)
        eventChannel = EventChannel(binaryMessenger, "flutter_beacon_event")
        eventChannel!!.setStreamHandler(beaconController.rangeNotifier)

        eventChannelMonitoring = EventChannel(binaryMessenger, "flutter_beacon_event_monitoring")
        eventChannelMonitoring!!.setStreamHandler(beaconController.monitorNotifier)

        eventChannelBluetoothState = EventChannel(binaryMessenger, "flutter_bluetooth_state_changed")
        eventChannelBluetoothState!!.setStreamHandler(BluetoothStateBroadcaster(activity.activity))

        eventChannelAuthorizationStatus = EventChannel(binaryMessenger, "flutter_authorization_status_changed")
        eventChannelAuthorizationStatus!!.setStreamHandler(PermissionBroadCaster(plugin))

        this.activityBinding = activity
    }

    fun reset() {
        channel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        eventChannelMonitoring?.setStreamHandler(null)
        eventChannelBluetoothState?.setStreamHandler(null)
        eventChannelAuthorizationStatus?.setStreamHandler(null)
        activityBinding = null
    }

    private fun initializeAndCheck(activity: ActivityPluginBinding, result: MethodChannel.Result) {
        plugin.initialize()

        if (!isBluetoothEnabled(activity.activity, result)) {
            openBluetoothSettings(activity, result)
            return
        }

        if (!areLocationServicesEnabled(activity.activity)) {
            openLocationSettings(activity.activity)
            return
        }

        if (!checkLocationPermission(activity)) {
            requestPermission(activity.activity)
        }

        if (plugin.beaconManager?.isBound(beaconController) == false) {
            plugin.beaconManager?.bind(beaconController)
        }

        result.success(true)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val activityBinding by lazy {
            activityBinding ?: error("beacon plugin not attached to activity")
        }
        when (call.method) {
            "initialize" -> {
                plugin.initialize()
                result.success(true)
            }
            "initializeAndCheck" -> initializeAndCheck(activityBinding, result)
            "setLocationAuthorizationTypeDefault" -> result.success(true)
            "authorizationStatus" -> {
                val granted = checkLocationPermission(activityBinding)
                result.success(if (granted) "ALLOWED" else "NOT_DETERMINED")
            }
            "checkLocationServicesIfEnabled" -> result.success(areLocationServicesEnabled(activityBinding.activity))
            "bluetoothState" -> {
                try {
                    val granted = isBluetoothEnabled(activityBinding.activity, result)
                    result.success(if(granted) "STATE_ON" else "STATE_OFF")
                } catch (ignored: RuntimeException) {
                }
            }
            "requestAuthorization" -> {
                if (checkLocationPermission(activityBinding)) return result.success(true)
                PermissionController.register(PermissionResponder(result, plugin))
                requestPermission(activityBinding.activity)
            }
            "openBluetoothSettings" -> openBluetoothSettings(activityBinding, result)
            "openLocationSettings" -> openLocationSettings(activityBinding.activity)
            "openApplicationSettings" -> {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", activityBinding.activity.packageName, null)
                }
                activityBinding.activity.startActivity(intent)
            }
            "close" -> {
                beaconController.close()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun openLocationSettings(activity: Activity) {
        val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        activity.startActivity(intent)
    }

    private fun openBluetoothSettings(activityBinding: ActivityPluginBinding, result: MethodChannel.Result) {
        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        activityBinding.activity.startActivityForResult(intent, FlutterBeaconPlugin.REQUEST_CODE_BLUETOOTH)
        activityBinding.addActivityResultListener(EnableBluetoothListener(activityBinding, result))
    }

    private fun requestPermission(activity: Activity) {
        ActivityCompat.requestPermissions(activity, arrayOf(
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION
        ), REQUEST_CODE_LOCATION)
    }

    private fun isBluetoothEnabled(activity: Activity, result: MethodChannel.Result): Boolean {
        val bluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        if (bluetoothManager == null) {
            result.error("404", "No bluetooth hardware found", "This device does not seem to have bluetooth capabilities")
            throw RuntimeException("Missing bluetooth")
        }

        return bluetoothManager.adapter.isEnabled
    }

    private fun checkLocationPermission(activityBinding: ActivityPluginBinding) =
            ContextCompat.checkSelfPermission(activityBinding.activity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun areLocationServicesEnabled(activity: Activity): Boolean {
        val locationManager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            locationManager.isLocationEnabled
        } else {
            @Suppress("DEPRECATION") // legacy support
            val mode = Settings.Secure
                    .getInt(activity.contentResolver, Settings.Secure.LOCATION_MODE,
                            Settings.Secure.LOCATION_MODE_OFF)
            mode != Settings.Secure.LOCATION_MODE_OFF
        }
    }
}
