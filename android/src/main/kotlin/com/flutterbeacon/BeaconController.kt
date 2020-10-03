package com.flutterbeacon

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.altbeacon.beacon.*

val checkResult: MethodChannel.Result? = null

class BeaconController(private val plugin: FlutterBeaconPlugin, private val activity: Activity) : BeaconConsumer {

    val rangeNotifier: RangingNotifier by lazy { RangingNotifier() }
    val monitorNotifier: MonitoringNotifier by lazy { MonitoringNotifier() }
    private val rangingRegions = mutableListOf<Region>()
    private val monitoringRegions = mutableListOf<Region>()

    override fun onBeaconServiceConnect() {
        if (checkResult != null) {
            checkResult.success(true)
        } else {
            startRanging()
            startMonitoring()
        }
    }

    fun loadRegions(target: MutableList<Region>, arguments: Any) {
        val regions = arguments as List<*>

        val new = regions.mapNotNull {
            val obj = it as Map<*, *>
            regionFromMap(obj)
        }

        target.clear()
        target.addAll(new)
    }

    fun startRanging() {
        if (rangingRegions.isEmpty()) {
            Log.e("RANGING", "Region ranging is null or empty. Ranging not started.")
            return
        }

        val manager = plugin.beaconManager ?: return
        manager.removeAllRangeNotifiers()
        manager.addRangeNotifier(rangeNotifier)

        rangingRegions.forEach(manager::startRangingBeaconsInRegion)

        if (plugin.beaconManager?.isBound(this) == false) {
            plugin.beaconManager?.bind(this)
        }
    }

    fun startMonitoring() {
        if (monitoringRegions.isEmpty()) {
            Log.e("MONITORING", "Region monitoring is null or empty. Ranging not started.")
            return
        }

        val manager = plugin.beaconManager ?: return
        manager.removeAllMonitorNotifiers()
        manager.addMonitorNotifier(monitorNotifier)

        monitoringRegions.forEach(manager::startMonitoringBeaconsInRegion)

        if (plugin.beaconManager?.isBound(this) == false) {
            plugin.beaconManager?.bind(this)
        }
    }

    override fun getApplicationContext(): Context = activity.applicationContext

    override fun unbindService(connection: ServiceConnection): Unit = activity.unbindService(connection)

    override fun bindService(intent: Intent, connection: ServiceConnection, flags: Int): Boolean =
            activity.bindService(intent, connection, flags)

    fun stopRanging() {
        val manager = plugin.beaconManager ?: return
        rangingRegions.forEach(manager::stopRangingBeaconsInRegion)
        manager.removeRangeNotifier(rangeNotifier)
    }

    fun stopMonitoring() {
        val manager = plugin.beaconManager ?: return
        monitoringRegions.forEach(manager::stopMonitoringBeaconsInRegion)
        manager.removeMonitorNotifier(monitorNotifier)
    }

    fun close() {
        val manager = plugin.beaconManager ?: return
        stopMonitoring()
        manager.removeAllMonitorNotifiers()
        stopRanging()
        manager.removeAllRangeNotifiers()
        if (manager.isBound(this)) {
            manager.unbind(this)
        }
    }

    inner class MonitoringNotifier : MonitorNotifier, EventChannel.StreamHandler {

        private var sink: EventChannel.EventSink? = null

        override fun didEnterRegion(region: Region) {
            val sink = sink ?: return
            val map = mapOf(
                    "event" to "didEnterRegion",
                    "region" to region.toMap()
            )
            sink.success(map)
        }

        override fun didExitRegion(region: Region) {
            val sink = sink ?: return
            val map = mapOf(
                    "event" to "didExitRegion",
                    "region" to region.toMap()
            )
            sink.success(map)
        }

        override fun didDetermineStateForRegion(state: Int, region: Region) {
            val sink = sink ?: return
            val map = mapOf(
                    "event" to "didDetermineStateForRegion",
                    "state" to state.toState(),
                    "region" to region.toMap()
            )
            sink.success(map)
        }

        override fun onListen(arguments: Any, events: EventChannel.EventSink) {
            loadRegions(monitoringRegions, arguments)
            startMonitoring()
            sink = events
        }

        override fun onCancel(arguments: Any?) {
            stopMonitoring()
            sink = null
        }
    }

    inner class RangingNotifier : RangeNotifier, EventChannel.StreamHandler {
        private var sink: EventChannel.EventSink? = null
        override fun didRangeBeaconsInRegion(beacons: MutableCollection<Beacon>, region: Region) {
            val sink = sink ?: return
            val map = mapOf(
                    "region" to region.toMap(),
                    "beacons" to beacons.toMapList()
            )
            sink.success(map)
        }

        override fun onListen(arguments: Any, events: EventChannel.EventSink) {
            loadRegions(rangingRegions, arguments)
            startRanging()
            sink = events
        }

        override fun onCancel(arguments: Any?) {
            stopRanging()
            sink = null
        }
    }
}
