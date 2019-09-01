package com.flutterbeacon;

import android.bluetooth.BluetoothAdapter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import io.flutter.plugin.common.EventChannel;

class FlutterBluetoothStateReceiver extends BroadcastReceiver {
  private EventChannel.EventSink eventSink;

  public FlutterBluetoothStateReceiver() { }

  public void setEventSink(EventChannel.EventSink eventSink) {
    this.eventSink = eventSink;
  }

  @Override
  public void onReceive(Context context, Intent intent) {
    if (eventSink == null) return;
    final String action = intent.getAction();

    if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
      final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
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
  }
}
