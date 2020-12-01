package com.flutterbeacon;

import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseSettings;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import org.altbeacon.beacon.Beacon;
import org.altbeacon.beacon.BeaconTransmitter;

import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

class FlutterBeaconBroadcast {
  private static final String TAG = FlutterBeaconBroadcast.class.getSimpleName();
  private final BeaconTransmitter beaconTransmitter;

  FlutterBeaconBroadcast(FlutterBeaconPlugin plugin) {
    this.beaconTransmitter = new BeaconTransmitter(plugin.getRegistrar().activity(), plugin.iBeaconLayout);
  }
  
  void isBroadcasting(@NonNull MethodChannel.Result result) {
    if (beaconTransmitter != null) {
      result.success(beaconTransmitter.isStarted());
    } else {
      result.success(false);
    }
  }
  
  void stopBroadcast(@NonNull MethodChannel.Result result) {
    if (beaconTransmitter != null) {
      beaconTransmitter.stopAdvertising();
      result.success(true);
    } else {
      result.success(false);
    }
  }
  
  @SuppressWarnings("rawtypes")
  void startBroadcast(Object arguments, @NonNull final MethodChannel.Result result) {
    if (!(arguments instanceof Map)) {
      result.error("Broadcast", "Invalid parameter", null);
      return;
    }

    Map map = (Map) arguments;
    final Beacon beacon = FlutterBeaconUtils.beaconFromMap(map);
    
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      Object advertisingMode = map.get("advertisingMode");
      if (advertisingMode instanceof Integer) {
        beaconTransmitter.setAdvertiseMode((Integer) advertisingMode);
      }
      Object advertisingTxPowerLevel = map.get("advertisingTxPowerLevel");
      if (advertisingTxPowerLevel instanceof Integer) {
        beaconTransmitter.setAdvertiseTxPowerLevel((Integer) advertisingTxPowerLevel);
      }
      beaconTransmitter.startAdvertising(beacon, new AdvertiseCallback() {
        @Override
        public void onStartSuccess(AdvertiseSettings settingsInEffect) {
          Log.d(TAG, "Start broadcasting = " + beacon);
          result.success(true);
        }

        @Override
        public void onStartFailure(int errorCode) {
          String error = "FEATURE_UNSUPPORTED";
          if (errorCode == ADVERTISE_FAILED_DATA_TOO_LARGE) {
            error = "DATA_TOO_LARGE";
          } else if (errorCode == ADVERTISE_FAILED_TOO_MANY_ADVERTISERS) {
            error = "TOO_MANY_ADVERTISERS";
          } else if (errorCode == ADVERTISE_FAILED_ALREADY_STARTED) {
            error = "ALREADY_STARTED";
          } else if (errorCode == ADVERTISE_FAILED_INTERNAL_ERROR) {
            error = "INTERNAL_ERROR";
          }
          Log.e(TAG, error);
          result.error("Broadcast", error, null);
        }
      });
    } else {
      Log.e(TAG, "FEATURE_UNSUPPORTED");
      result.error("Broadcast", "FEATURE_UNSUPPORTED", null);
    }
  }
}
