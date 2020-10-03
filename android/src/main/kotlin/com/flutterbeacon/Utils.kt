package com.flutterbeacon

import android.util.Log
import org.altbeacon.beacon.Beacon
import org.altbeacon.beacon.Identifier
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.Region
import java.util.*

fun Int.toState() =
        if (this == MonitorNotifier.INSIDE) "INSIDE" else if (this == MonitorNotifier.OUTSIDE) "OUTSIDE" else "UNKNOWN"


fun Collection<Beacon>.toMapList(): List<Map<String, Any>> {
    return map(Beacon::toMap)
}

private fun Beacon.toMap(): Map<String, Any> {
    return mapOf(
            "proximityUUID" to id1.toString().toUpperCase(Locale.getDefault()),
            "major" to id2.toInt(),
            "minor" to id3.toInt(),
            "rssi" to rssi,
            "txPower" to txPower,
            "accuracy" to "%.2f".format(Locale.getDefault(), distance),
            "macAddress" to bluetoothAddress
    )
}

fun Region.toMap(): Map<String, Any> {
    val map: MutableMap<String, Any> = HashMap()
    map["identifier"] = uniqueId
    if (id1 != null) {
        map["proximityUUID"] = id1.toString()
    }
    if (id2 != null) {
        map["major"] = id2.toInt()
    }
    if (id3 != null) {
        map["minor"] = id3.toInt()
    }
    return map.toMap()
}

fun regionFromMap(map: Map<*, *>): Region? {
    return try {
        var identifier = ""
        val identifiers: MutableList<Identifier> = ArrayList()
        val objectIdentifier = map["identifier"]
        if (objectIdentifier is String) {
            identifier = objectIdentifier.toString()
        }
        val proximityUUID = map["proximityUUID"]
        if (proximityUUID is String) {
            identifiers.add(Identifier.parse(proximityUUID as String?))
        }
        val major = map["major"]
        if (major is Int) {
            identifiers.add(Identifier.fromInt(major))
        }
        val minor = map["minor"]
        if (minor is Int) {
            identifiers.add(Identifier.fromInt(minor))
        }
        Region(identifier, identifiers)
    } catch (e: IllegalArgumentException) {
        Log.e("REGION", "Error : $e")
        null
    }
}
