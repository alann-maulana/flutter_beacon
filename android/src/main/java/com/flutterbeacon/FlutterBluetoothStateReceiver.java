package com.flutterbeacon;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import io.flutter.plugin.common.EventChannel;

class FlutterBluetoothStateReceiver extends BroadcastReceiver implements EventChannel.StreamHandler {
  private final Context context;
  private EventChannel.EventSink eventSink;

  public FlutterBluetoothStateReceiver(Context context) {
    this.context = context;
  }

  @Override
  public void onReceive(Context context, Intent intent) {
    if (eventSink == null) return;
    final String action = intent.getAction();

    if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
      final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
      sendState(state);
    }
  }

  private void sendState(int state) {
    switch (state) {
      case BluetoothAdapter.STATE_OFF:
        eventSink.success("STATE_OFF");
        break;
      case BluetoothAdapter.STATE_TURNING_OFF:
        eventSink.success("STATE_TURNING_OFF");
        break;
      case BluetoothAdapter.STATE_ON:
        eventSink.success("STATE_ON");
        break;
      case BluetoothAdapter.STATE_TURNING_ON:
        eventSink.success("STATE_TURNING_ON");
        break;
      default:
        eventSink.error("BLUETOOTH_STATE", "invalid bluetooth adapter state", null);
        break;
    }
  }

  @SuppressLint("MissingPermission")
  @Override
  public void onListen(Object o, EventChannel.EventSink eventSink) {
    int state = BluetoothAdapter.STATE_OFF;

    BluetoothManager bluetoothManager = (BluetoothManager)
        context.getSystemService(Context.BLUETOOTH_SERVICE);
    if (bluetoothManager != null) {
      BluetoothAdapter adapter = bluetoothManager.getAdapter();
      if (adapter != null) {
        state = adapter.getState();
      }
    }
    this.eventSink = eventSink;
    this.sendState(state);

    IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
    context.registerReceiver(this, filter);
  }

  @Override
  public void onCancel(Object o) {
    context.unregisterReceiver(this);
  }
}
