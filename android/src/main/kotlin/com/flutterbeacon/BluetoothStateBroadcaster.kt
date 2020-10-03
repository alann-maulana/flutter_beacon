package com.flutterbeacon

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.*
import io.flutter.plugin.common.EventChannel

class BluetoothStateBroadcaster(private val context: ContextWrapper) : BroadcastReceiver(), EventChannel.StreamHandler {

    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        var state = BluetoothAdapter.STATE_OFF

        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        if (bluetoothManager != null) {
            val adapter = bluetoothManager.adapter
            if (adapter != null) {
                state = adapter.state
            }
        }
        sink = events
        events.sendState(state)

        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        context.registerReceiver(this, filter)
    }

    override fun onCancel(arguments: Any?) {
        context.unregisterReceiver(this)
    }

    override fun onReceive(context: Context, intent: Intent) {
        val sink = sink ?: return
        val action = intent.action

        if (BluetoothAdapter.ACTION_STATE_CHANGED == action) {
            val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
            sink.sendState(state)
        }
    }

    private fun EventChannel.EventSink.sendState(state: Int) {
        when (state) {
            BluetoothAdapter.STATE_OFF -> success("STATE_OFF")
            BluetoothAdapter.STATE_TURNING_OFF -> success("STATE_TURNING_OFF")
            BluetoothAdapter.STATE_ON -> success("STATE_ON")
            BluetoothAdapter.STATE_TURNING_ON -> success("STATE_TURNING_ON")
            else -> error("BLUETOOTH_STATE", "invalid bluetooth adapter state", null)
        }
    }
}
