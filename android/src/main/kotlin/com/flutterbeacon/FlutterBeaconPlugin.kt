package com.flutterbeacon

import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.BeaconParser

@RequiresApi(Build.VERSION_CODES.M)
class FlutterBeaconPlugin : FlutterPlugin, ActivityAware {

    var activity: ActivityPluginBinding? = null
        private set
    private var binaryMessenger: BinaryMessenger? = null
    var beaconManager: BeaconManager? = null
        private set
    lateinit var beaconController: BeaconController
    val communicator: PlattformComunicator = PlattformComunicator(this)

    private val iBeaconLayout = BeaconParser()
            .setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24")

    fun initialize() {
        val activity = activity
        requireNotNull(activity) { "Plugin is not fully initialized" }
        val beaconManager = BeaconManager.getInstanceForApplication(activity.activity)
        this.beaconManager = beaconManager
        if (!beaconManager.beaconParsers.contains(iBeaconLayout)) {
            beaconManager.beaconParsers.add(iBeaconLayout)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binaryMessenger = binding.binaryMessenger
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binaryMessenger = null
        communicator.reset()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        communicator.init(binaryMessenger!!, binding)
        binding.addRequestPermissionsResultListener(PermissionController)
        beaconController = BeaconController(this, binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges(): Unit = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding): Unit = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        communicator.reset()
        activity = null
    }

    companion object {
        const val REQUEST_CODE_LOCATION: Int = 1234
        const val REQUEST_CODE_BLUETOOTH: Int = 5678
    }
}
