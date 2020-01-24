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
import android.location.LocationManager;
import android.os.Build;
import android.os.RemoteException;
import android.provider.Settings;
import android.util.Log;

import androidx.annotation.NonNull;
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

import io.flutter.plugin.common.BinaryMessenger;
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
  private final BeaconParser iBeaconLayout = new BeaconParser()
      .setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");

  private static final int REQUEST_CODE_LOCATION = 1234;
  private static final int REQUEST_CODE_BLUETOOTH = 5678;

  private final Registrar registrar;
  private BeaconManager beaconManager;
  private Result flutterResult, flutterResultBluetooth;
  private EventChannel.EventSink eventSinkRanging, eventSinkMonitoring;
  private List<Region> regionRanging;
  private List<Region> regionMonitoring;

  private MethodChannel channel;
  private EventChannel eventChannel;
  private EventChannel eventChannelMonitoring;
  private EventChannel eventChannelBluetoothState;
  private EventChannel eventChannelAuthorizationStatus;

  private FlutterBeaconPlugin(Registrar registrar) {
    this.registrar = registrar;
  }

  public static void registerWith(Registrar registrar) {
    final FlutterBeaconPlugin instance = new FlutterBeaconPlugin(registrar);
    instance.setupChannels(registrar.messenger(), registrar.context());
    registrar.addActivityResultListener(instance);
    registrar.addRequestPermissionsResultListener(instance);
  }

  private void setupChannels(BinaryMessenger messenger, Context context) {
    channel = new MethodChannel(messenger, "flutter_beacon");
    channel.setMethodCallHandler(this);

    eventChannel = new EventChannel(messenger, "flutter_beacon_event");
    eventChannel.setStreamHandler(rangingStreamHandler);

    eventChannelMonitoring = new EventChannel(messenger, "flutter_beacon_event_monitoring");
    eventChannelMonitoring.setStreamHandler(monitoringStreamHandler);

    eventChannelBluetoothState = new EventChannel(messenger, "flutter_bluetooth_state_changed");
    eventChannelBluetoothState.setStreamHandler(new FlutterBluetoothStateReceiver(context));

    eventChannelAuthorizationStatus = new EventChannel(messenger, "flutter_authorization_status_changed");
    eventChannelAuthorizationStatus.setStreamHandler(null);
  }

  private void teardownChannels() {
    channel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
    eventChannelMonitoring.setStreamHandler(null);
    eventChannelBluetoothState.setStreamHandler(null);
    eventChannelAuthorizationStatus.setStreamHandler(null);

    channel = null;
    eventChannel = null;
    eventChannelMonitoring = null;
    eventChannelBluetoothState = null;
    eventChannelAuthorizationStatus = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("initialize")) {
      initialize();
      if (beaconManager != null && !beaconManager.isBound(beaconConsumer)) {
        this.flutterResult = result;
        this.beaconManager.bind(beaconConsumer);
        return;
      }

      result.success(true);
      return;
    }

    if (call.method.equals("initializeAndCheck")) {
      initializeAndCheck(result);
      return;
    }

    if (call.method.equals("authorizationStatus")) {
      result.success(checkLocationServicesPermission() ? "ALLOWED" : "DENIED");
      return;
    }

    if (call.method.equals("checkLocationServicesIfEnabled")) {
      result.success(checkLocationServicesIfEnabled());
      return;
    }

    if (call.method.equals("bluetoothState")) {
      try {
        boolean flag = checkBluetoothIfEnabled();
        result.success(flag ? "STATE_ON" : "STATE_OFF");
        return;
      } catch (RuntimeException ignored) {

      }

      result.success("STATE_UNSUPPORTED");
      return;
    }

    if (call.method.equals("requestAuthorization")) {
      if (!checkLocationServicesPermission()) {
        this.flutterResult = result;
        requestAuthorization();
        return;
      }

      result.success(true);
      return;
    }

    if (call.method.equals("openBluetoothSettings")) {
      if (!checkBluetoothIfEnabled()) {
        this.flutterResultBluetooth = result;
        openBluetoothSettings();
        return;
      }

      result.success(true);
      return;
    }

    if (call.method.equals("openLocationSettings")) {
      openLocationSettings();
      result.success(true);
      return;
    }

    if (call.method.equals("openApplicationSettings")) {
      result.notImplemented();
      return;
    }

    if (call.method.equals("close")) {
      if (beaconManager != null) {
        stopRanging();
        beaconManager.removeAllRangeNotifiers();
        stopMonitoring();
        beaconManager.removeAllMonitorNotifiers();
        if (beaconManager.isBound(beaconConsumer)) {
          beaconManager.unbind(beaconConsumer);
        }
      }
      result.success(true);
      return;
    }

    result.notImplemented();
  }

  private void initialize() {
    beaconManager = BeaconManager.getInstanceForApplication(registrar.context());
    if (!beaconManager.getBeaconParsers().contains(iBeaconLayout)) {
      beaconManager.getBeaconParsers().clear();
      beaconManager.getBeaconParsers().add(iBeaconLayout);
    }
  }

  private void initializeAndCheck(Result result) {
    initialize();

    if (checkLocationServicesPermission() && checkBluetoothIfEnabled() && checkLocationServicesIfEnabled()) {
      if (result != null) {
        result.success(true);
        return;
      }
    }

    flutterResult = result;
    if (!checkBluetoothIfEnabled()) {
      openBluetoothSettings();
      return;
    }

    if (!checkLocationServicesPermission()) {
      requestAuthorization();
      return;
    }

    if (!checkLocationServicesIfEnabled()) {
      openLocationSettings();
      return;
    }

    if (beaconManager != null && !beaconManager.isBound(beaconConsumer)) {
      if (result != null) {
        this.flutterResult = result;
      }

      beaconManager.bind(beaconConsumer);
      return;
    }

    if (result != null) {
      result.success(true);
    }
  }

  private void openLocationSettings() {
    Intent intent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    registrar.context().startActivity(intent);
  }

  private void openBluetoothSettings() {
    Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
    registrar.activity().startActivityForResult(intent, REQUEST_CODE_BLUETOOTH);
  }

  private void requestAuthorization() {
    ActivityCompat.requestPermissions(registrar.activity(), new String[]{
        Manifest.permission.ACCESS_COARSE_LOCATION
    }, REQUEST_CODE_LOCATION);
  }

  // region CHECKER STATE
  private boolean checkLocationServicesPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      return ContextCompat.checkSelfPermission(registrar.context(),
          Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    return true;
  }

  private boolean checkLocationServicesIfEnabled() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      LocationManager locationManager = (LocationManager) registrar.context().getSystemService(Context.LOCATION_SERVICE);
      return locationManager != null && locationManager.isLocationEnabled();
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      int mode = Settings.Secure.getInt(registrar.context().getContentResolver(), Settings.Secure.LOCATION_MODE,
          Settings.Secure.LOCATION_MODE_OFF);
      return (mode != Settings.Secure.LOCATION_MODE_OFF);
    }

    return true;
  }

  @SuppressLint("MissingPermission")
  private boolean checkBluetoothIfEnabled() {
    BluetoothManager bluetoothManager = (BluetoothManager)
        registrar.activeContext().getSystemService(Context.BLUETOOTH_SERVICE);
    if (bluetoothManager == null) {
      throw new RuntimeException("No bluetooth service");
    }

    BluetoothAdapter adapter = bluetoothManager.getAdapter();

    return (adapter != null) && (adapter.isEnabled());
  }
  // endregion

  private final BeaconConsumer beaconConsumer = new BeaconConsumer() {
    @Override
    public void onBeaconServiceConnect() {
      if (FlutterBeaconPlugin.this.flutterResult != null) {
        FlutterBeaconPlugin.this.flutterResult.success(true);
        FlutterBeaconPlugin.this.flutterResult = null;
      } else {
        startRanging();
        startMonitoring();
      }
    }

    @Override
    public Context getApplicationContext() {
      return registrar.context().getApplicationContext();
    }

    @Override
    public void unbindService(ServiceConnection serviceConnection) {
      registrar.context().unbindService(serviceConnection);
    }

    @Override
    public boolean bindService(Intent intent, ServiceConnection serviceConnection, int i) {
      return registrar.context().bindService(intent, serviceConnection, i);
    }
  };

  //region RANGING
  private final EventChannel.StreamHandler rangingStreamHandler = new EventChannel.StreamHandler() {
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
      Log.d("RANGING", "Start ranging = " + o);
      startRanging(o, eventSink);
    }

    @Override
    public void onCancel(Object o) {
      Log.d("RANGING", "Stop ranging = " + o);
      stopRanging();
    }
  };

  private void startRanging(Object o, EventChannel.EventSink eventSink) {
    if (o instanceof List) {
      List list = (List) o;
      if (regionRanging == null) {
        regionRanging = new ArrayList<>();
      } else {
        regionRanging.clear();
      }
      for (Object object : list) {
        if (object instanceof Map) {
          Map map = (Map) object;
          Region region = FlutterBeaconUtils.regionFromMap(map);
          if (region != null) {
            regionRanging.add(region);
          }
        }
      }
    } else {
      eventSink.error("Beacon", "invalid region for ranging", null);
      return;
    }
    eventSinkRanging = eventSink;
    if (beaconManager != null && !beaconManager.isBound(beaconConsumer)) {
      beaconManager.bind(beaconConsumer);
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
      if (beaconManager != null) {
        beaconManager.removeAllRangeNotifiers();
        beaconManager.addRangeNotifier(rangeNotifier);
        for (Region region : regionRanging) {
          beaconManager.startRangingBeaconsInRegion(region);
        }
      }
    } catch (RemoteException e) {
      if (eventSinkRanging != null) {
        eventSinkRanging.error("Beacon", e.getLocalizedMessage(), null);
      }
    }
  }

  private void stopRanging() {
    if (regionRanging != null && !regionRanging.isEmpty()) {
      try {
        for (Region region : regionRanging) {
          beaconManager.stopRangingBeaconsInRegion(region);
        }

        beaconManager.removeRangeNotifier(rangeNotifier);
      } catch (RemoteException ignored) {
      }
    }
    eventSinkRanging = null;
  }

  private final RangeNotifier rangeNotifier = new RangeNotifier() {
    @Override
    public void didRangeBeaconsInRegion(Collection<Beacon> collection, Region region) {
      if (eventSinkRanging != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        map.put("beacons", FlutterBeaconUtils.beaconsToArray(new ArrayList<>(collection)));
        eventSinkRanging.success(map);
      }
    }
  };
  //endregion

  //region MONITORING
  private final EventChannel.StreamHandler monitoringStreamHandler = new EventChannel.StreamHandler() {
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
      startMonitoring(o, eventSink);
    }

    @Override
    public void onCancel(Object o) {
      stopMonitoring();
    }
  };

  private void startMonitoring(Object o, EventChannel.EventSink eventSink) {
    Log.d(TAG, "START MONITORING=" + o);
    if (o instanceof List) {
      List list = (List) o;
      if (regionMonitoring == null) {
        regionMonitoring = new ArrayList<>();
      } else {
        regionMonitoring.clear();
      }
      for (Object object : list) {
        if (object instanceof Map) {
          Map map = (Map) object;
          Region region = FlutterBeaconUtils.regionFromMap(map);
          regionMonitoring.add(region);
        }
      }
    } else {
      eventSink.error("Beacon", "invalid region for monitoring", null);
      return;
    }
    eventSinkMonitoring = eventSink;
    if (beaconManager != null && !beaconManager.isBound(beaconConsumer)) {
      beaconManager.bind(beaconConsumer);
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
      beaconManager.removeAllMonitorNotifiers();
      beaconManager.addMonitorNotifier(monitorNotifier);
      for (Region region : regionMonitoring) {
        beaconManager.startMonitoringBeaconsInRegion(region);
      }
    } catch (RemoteException e) {
      if (eventSinkMonitoring != null) {
        eventSinkMonitoring.error("Beacon", e.getLocalizedMessage(), null);
      }
    }
  }

  private void stopMonitoring() {
    if (regionMonitoring != null && !regionMonitoring.isEmpty()) {
      try {
        for (Region region : regionMonitoring) {
          beaconManager.stopMonitoringBeaconsInRegion(region);
        }
        beaconManager.removeMonitorNotifier(monitorNotifier);
      } catch (RemoteException ignored) {
      }
    }
    eventSinkMonitoring = null;
  }

  private final MonitorNotifier monitorNotifier = new MonitorNotifier() {
    @Override
    public void didEnterRegion(Region region) {
      if (eventSinkMonitoring != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("event", "didEnterRegion");
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        eventSinkMonitoring.success(map);
      }
    }

    @Override
    public void didExitRegion(Region region) {
      if (eventSinkMonitoring != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("event", "didExitRegion");
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        eventSinkMonitoring.success(map);
      }
    }

    @Override
    public void didDetermineStateForRegion(int state, Region region) {
      if (eventSinkMonitoring != null) {
        Map<String, Object> map = new HashMap<>();
        map.put("event", "didDetermineStateForRegion");
        map.put("state", FlutterBeaconUtils.parseState(state));
        map.put("region", FlutterBeaconUtils.regionToMap(region));
        eventSinkMonitoring.success(map);
      }
    }
  };
  //endregion

  // region ACTIVITY CALLBACK
  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    if (requestCode != REQUEST_CODE_LOCATION) {
      return false;
    }

    boolean locationServiceAllowed = false;
    if (permissions.length > 0 && grantResults.length > 0) {
      String permission = permissions[0];
      if (!ActivityCompat.shouldShowRequestPermissionRationale(registrar.activity(), permission)) {
        int grantResult = grantResults[0];
        if (grantResult == PackageManager.PERMISSION_GRANTED) {
          //allowed
          locationServiceAllowed = true;
        }
      }
    }

    if (flutterResult != null) {
      if (locationServiceAllowed) {
        flutterResult.success(true);
      } else {
        flutterResult.error("Beacon", "location services not allowed", null);
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
        requestAuthorization();
      } else {
        if (flutterResultBluetooth != null) {
          flutterResultBluetooth.success(true);
          flutterResultBluetooth = null;
        } else if (flutterResult != null) {
          flutterResult.success(true);
          flutterResult = null;
        }
      }
    } else {
      if (flutterResultBluetooth != null) {
        flutterResultBluetooth.error("Beacon", "bluetooth disabled", null);
        flutterResultBluetooth = null;
      } else if (flutterResult != null) {
        flutterResult.error("Beacon", "bluetooth disabled", null);
        flutterResult = null;
      }
    }

    return bluetoothEnabled;
  }
  // endregion
}
