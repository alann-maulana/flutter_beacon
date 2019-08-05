package com.flutterbeacon;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.RemoteException;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import org.altbeacon.beacon.Beacon;
import org.altbeacon.beacon.BeaconConsumer;
import org.altbeacon.beacon.BeaconManager;
import org.altbeacon.beacon.BeaconParser;
import org.altbeacon.beacon.MonitorNotifier;
import org.altbeacon.beacon.RangeNotifier;
import org.altbeacon.beacon.Region;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class FlutterBeaconPlugin implements MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {
  private static final String TAG = FlutterBeaconPlugin.class.getSimpleName();

  private static final int REQUEST_CODE_LOCATION = 1234;
  private static final int REQUEST_CODE_BLUETOOTH = 5678;

  private final Registrar registrar;
  private BeaconManager beaconManager;
  private Result flutterResult;
  private EventChannel.EventSink eventSinkRanging, eventSinkMonitoring;
  private List<Region> regionRanging;
  private List<Region> regionMonitoring;

  private FlutterBeaconPlugin(Registrar registrar) {
    this.registrar = registrar;
  }

  private Registrar getRegistrar() {
    return registrar;
  }

  public static void registerWith(Registrar registrar) {
    final FlutterBeaconPlugin instance = new FlutterBeaconPlugin(registrar);
    instance.getRegistrar().addActivityResultListener(instance);
    instance.getRegistrar().addRequestPermissionsResultListener(instance);

    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_beacon");
    channel.setMethodCallHandler(instance);

    final EventChannel eventChannel =
        new EventChannel(registrar.messenger(), "flutter_beacon_event");
    eventChannel.setStreamHandler(instance.rangingStreamHandler);

    final EventChannel eventChannelMonitoring =
        new EventChannel(registrar.messenger(), "flutter_beacon_event_monitoring");
    eventChannelMonitoring.setStreamHandler(instance.monitoringStreamHandler);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("initialize")) {
      this.flutterResult = result;
      initialize();
    } else {
      result.notImplemented();
    }
  }

  private void initialize() {
    this.beaconManager = BeaconManager.getInstanceForApplication(registrar.activity());

    BeaconParser iBeaconLayout = new BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");
    beaconManager.getBeaconParsers().clear();
    beaconManager.getBeaconParsers().add(iBeaconLayout);

    if (checkLocationServicesPermission() && checkBluetoothPoweredOn()) {
      if (this.flutterResult != null) {
        this.flutterResult.success(true);
        this.flutterResult = null;
      }
    } else {
      if (!checkBluetoothPoweredOn()) {
        registrar.activity().startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE), REQUEST_CODE_BLUETOOTH);
        return;
      }

      if (!checkLocationServicesPermission()) {
        ActivityCompat.requestPermissions(registrar.activity(), new String[]{
            Manifest.permission.ACCESS_COARSE_LOCATION
        }, REQUEST_CODE_LOCATION);
      }
    }
  }

  private boolean checkLocationServicesPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      return ContextCompat.checkSelfPermission(registrar.activity(),
          Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    return true;
  }

  @SuppressLint("MissingPermission")
  private boolean checkBluetoothPoweredOn() {
    BluetoothManager bluetoothManager = (BluetoothManager)
        registrar.activeContext().getSystemService(Context.BLUETOOTH_SERVICE);
    if (bluetoothManager == null) {
      throw new RuntimeException("No bluetooth service");
    }

    BluetoothAdapter adapter = bluetoothManager.getAdapter();

    return (adapter != null) && (adapter.isEnabled());
  }

  private EventChannel.StreamHandler rangingStreamHandler = new EventChannel.StreamHandler() {
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
      FlutterBeaconPlugin.this.startRanging(o, eventSink);
    }

    @Override
    public void onCancel(Object o) {
      FlutterBeaconPlugin.this.stopRanging();
    }
  };

  private void startRanging(Object o, EventChannel.EventSink eventSink) {
    Log.d(TAG, "START RANGING=" + o);
    if (o instanceof List) {
      //noinspection unchecked
      List<Object> list = (List<Object>) o;
      if (this.regionRanging == null) {
        this.regionRanging = new ArrayList<>();
      } else {
        this.regionRanging.clear();
      }
      for (Object object : list) {
        if (object instanceof Map) {
          //noinspection unchecked
          Region region = FlutterBeaconUtils.regionFromMap((Map<String, Object>) object);
          this.regionRanging.add(region);
        }
      }
    } else {
      eventSink.error("Beacon", "invalid region for ranging", null);
      return;
    }
    this.eventSinkRanging = eventSink;
    if (!this.beaconManager.isBound(beaconConsumer)) {
      this.beaconManager.bind(beaconConsumer);
    } else {
      startRanging();
    }
  }

  private void startRanging() {
    if (regionRanging == null || regionRanging.isEmpty()) {
      Log.e("RANGING", "Region ranging is null or empty. Ranging not started.");
      return;
    }

    try {
      FlutterBeaconPlugin.this.beaconManager.removeAllRangeNotifiers();
      FlutterBeaconPlugin.this.beaconManager.addRangeNotifier(rangeNotifier);
      for (Region region : regionRanging) {
        beaconManager.startRangingBeaconsInRegion(region);
      }
    } catch (RemoteException e) {
      if (FlutterBeaconPlugin.this.eventSinkRanging != null) {
        FlutterBeaconPlugin.this.eventSinkRanging.error("Beacon", e.getLocalizedMessage(), null);
      }
    }
  }

  private void stopRanging() {
    this.eventSinkRanging = null;
  }

  private final BeaconConsumer beaconConsumer = new BeaconConsumer() {
    @Override
    public void onBeaconServiceConnect() {
      startRanging();
      startMonitoring();
    }

    @Override
    public Context getApplicationContext() {
      return registrar.activity().getApplicationContext();
    }

    @Override
    public void unbindService(ServiceConnection serviceConnection) {
      registrar.activity().unbindService(serviceConnection);
    }

    @Override
    public boolean bindService(Intent intent, ServiceConnection serviceConnection, int i) {
      return registrar.activity().bindService(intent, serviceConnection, i);
    }
  };

  private final RangeNotifier rangeNotifier = new RangeNotifier() {
    @Override
    public void didRangeBeaconsInRegion(Collection<Beacon> collection, Region region) {
      if (FlutterBeaconPlugin.this.eventSinkRanging != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        map.put("beacons", FlutterBeaconUtils.beaconsToArray(new ArrayList<>(collection)));
        FlutterBeaconPlugin.this.eventSinkRanging.success(map);
      }
    }
  };

  private EventChannel.StreamHandler monitoringStreamHandler = new EventChannel.StreamHandler() {
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
      FlutterBeaconPlugin.this.startMonitoring(o, eventSink);
    }

    @Override
    public void onCancel(Object o) {
      FlutterBeaconPlugin.this.stopMonitoring();
    }
  };

  private void startMonitoring(Object o, EventChannel.EventSink eventSink) {
    Log.d(TAG, "START MONITORING=" + o);
    if (o instanceof List) {
      //noinspection unchecked
      List<Object> list = (List<Object>) o;
      if (this.regionMonitoring == null) {
        this.regionMonitoring = new ArrayList<>();
      } else {
        this.regionMonitoring.clear();
      }
      for (Object object : list) {
        if (object instanceof Map) {
          //noinspection unchecked
          Region region = FlutterBeaconUtils.regionFromMap((Map<String, Object>) object);
          this.regionMonitoring.add(region);
        }
      }
    } else {
      eventSink.error("Beacon", "invalid region for monitoring", null);
      return;
    }
    this.eventSinkMonitoring = eventSink;
    if (!this.beaconManager.isBound(beaconConsumer)) {
      this.beaconManager.bind(beaconConsumer);
    } else {
      startMonitoring();
    }
  }

  private void startMonitoring() {
    if (regionMonitoring == null || regionMonitoring.isEmpty()) {
      Log.e("MONITORING", "Region monitoring is null or empty. Monitoring not started.");
      return;
    }

    try {
      FlutterBeaconPlugin.this.beaconManager.removeAllMonitorNotifiers();
      FlutterBeaconPlugin.this.beaconManager.addMonitorNotifier(monitorNotifier);
      for (Region region : regionMonitoring) {
        beaconManager.startMonitoringBeaconsInRegion(region);
      }
    } catch (RemoteException e) {
      if (FlutterBeaconPlugin.this.eventSinkMonitoring != null) {
        FlutterBeaconPlugin.this.eventSinkMonitoring.error("Beacon", e.getLocalizedMessage(), null);
      }
    }
  }

  private void stopMonitoring() {
    this.eventSinkMonitoring = null;
    beaconManager.unbind(beaconConsumer);
  }

  private MonitorNotifier monitorNotifier = new MonitorNotifier() {
    @Override
    public void didEnterRegion(Region region) {
      if (FlutterBeaconPlugin.this.eventSinkMonitoring != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("event", "didEnterRegion");
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        FlutterBeaconPlugin.this.eventSinkMonitoring.success(map);
      }
    }

    @Override
    public void didExitRegion(Region region) {
      if (FlutterBeaconPlugin.this.eventSinkMonitoring != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("event", "didExitRegion");
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        FlutterBeaconPlugin.this.eventSinkMonitoring.success(map);
      }
    }

    @Override
    public void didDetermineStateForRegion(int state, Region region) {
      if (FlutterBeaconPlugin.this.eventSinkMonitoring != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("event", "didDetermineStateForRegion");
        map.put("state", state == MonitorNotifier.INSIDE ? "INSIDE" : state == MonitorNotifier.OUTSIDE ? "OUTSIDE" : "UNKNOWN");
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        FlutterBeaconPlugin.this.eventSinkMonitoring.success(map);
      }
    }
  };

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    boolean locationServiceAllowed = false;
    String permission = permissions[0];
    if (requestCode == REQUEST_CODE_LOCATION && grantResults.length > 0) {
      if (!ActivityCompat.shouldShowRequestPermissionRationale(registrar.activity(), permission)) {
        int grantResult = grantResults[0];
        if (grantResult == PackageManager.PERMISSION_GRANTED) {
          //allowed
          locationServiceAllowed = true;
        }
      }
    }

    if (this.flutterResult != null) {
      if (locationServiceAllowed) {
        this.flutterResult.success(true);
      } else {
        this.flutterResult.error("Beacon", "location services not allowed", null);
      }
      this.flutterResult = null;
    }

    return locationServiceAllowed;
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
    boolean bluetoothEnabled = requestCode == REQUEST_CODE_BLUETOOTH && resultCode == Activity.RESULT_OK;

    if (bluetoothEnabled) {
      if (!checkLocationServicesPermission()) {
        ActivityCompat.requestPermissions(registrar.activity(), new String[]{
            Manifest.permission.ACCESS_COARSE_LOCATION
        }, REQUEST_CODE_LOCATION);
      } else {
        if (this.flutterResult != null) {
          this.flutterResult.success(true);
          this.flutterResult = null;
        }
      }
    } else {
      if (this.flutterResult != null) {
        this.flutterResult.error("Beacon", "bluetooth disabled", null);
        this.flutterResult = null;
      }
    }

    return bluetoothEnabled;
  }
}
