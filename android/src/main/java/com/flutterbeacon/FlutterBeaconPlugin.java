package com.flutterbeacon;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.RemoteException;
import android.provider.Settings;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
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
  private BeaconParser iBeaconLayout = new BeaconParser()
      .setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");

  private static final int REQUEST_CODE_LOCATION = 1234;
  private static final int REQUEST_CODE_BLUETOOTH = 5678;

  private final Registrar registrar;
  private FlutterBluetoothStateReceiver mReceiver = new FlutterBluetoothStateReceiver();
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

    final EventChannel eventChannelBluetoothState =
        new EventChannel(registrar.messenger(), "flutter_bluetooth_state_changed");
    eventChannelBluetoothState.setStreamHandler(instance.bluetoothStateChangeStreamHandler);

    final EventChannel eventChannelAuthorizationStatus =
        new EventChannel(registrar.messenger(), "flutter_authorization_status_changed");
    eventChannelAuthorizationStatus.setStreamHandler(null);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("initialize")) {
      initialize(result);
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
      } catch (RuntimeException ignored) {
        result.success("STATE_UNSUPPORTED");
      }
      return;
    }

    if (call.method.equals("requestAuthorization")) {
      if (!checkLocationServicesPermission()) {
        this.flutterResult = result;
        ActivityCompat.requestPermissions(registrar.activity(), new String[]{
            Manifest.permission.ACCESS_COARSE_LOCATION
        }, REQUEST_CODE_LOCATION);
      } else {
        result.success(true);
      }
      return;
    }

    if (call.method.equals("openBluetoothSettings")) {
      if (!checkBluetoothIfEnabled()) {
        this.flutterResult = result;
        Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
        registrar.activity().startActivityForResult(intent, REQUEST_CODE_BLUETOOTH);
        return;
      } else {
        result.success(true);
      }
      return;
    }

    if (call.method.equals("openLocationSettings")) {
      Intent intent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
      registrar.activity().startActivity(intent);
      result.success(true);
      return;
    }

    //noinspection StatementWithEmptyBody
    if (call.method.equals("openApplicationSettings")) {
      // not implemented
    }

    if (call.method.equals("close")) {
      if (beaconManager != null) {
        beaconManager.removeAllRangeNotifiers();
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

  private void initialize(@Nullable Result result) {
    beaconManager = BeaconManager.getInstanceForApplication(registrar.activity());
    if (!beaconManager.getBeaconParsers().contains(iBeaconLayout)) {
      beaconManager.getBeaconParsers().clear();
      beaconManager.getBeaconParsers().add(iBeaconLayout);
    }
    if (beaconManager != null && !beaconManager.isBound(beaconConsumer)) {
      beaconManager.bind(beaconConsumer);
    }

    if (result != null) {
      result.success(true);
    }
  }

  private void initializeAndCheck(Result result) {
    initialize(null);

    if (checkLocationServicesPermission() && checkBluetoothIfEnabled()) {
      if (result != null) {
        result.success(true);
        return;
      }
    }

    flutterResult = result;
    if (!checkBluetoothIfEnabled()) {
      Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
      registrar.activity().startActivityForResult(intent, REQUEST_CODE_BLUETOOTH);
      return;
    }

    if (!checkLocationServicesPermission()) {
      ActivityCompat.requestPermissions(registrar.activity(), new String[]{
          Manifest.permission.ACCESS_COARSE_LOCATION
      }, REQUEST_CODE_LOCATION);
    }
  }

  // region CHECKER STATE
  private boolean checkLocationServicesPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      return ContextCompat.checkSelfPermission(registrar.activity(),
          Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    return true;
  }

  private boolean checkLocationServicesIfEnabled() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      try {
        return Settings.Secure.LOCATION_MODE_OFF !=
            Settings.Secure.getInt(registrar.activity().getContentResolver(), Settings.Secure.LOCATION_MODE);
      } catch (Settings.SettingNotFoundException ignored) {
        return false;
      }
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

  private EventChannel.StreamHandler bluetoothStateChangeStreamHandler = new EventChannel.StreamHandler() {
    @SuppressLint("MissingPermission")
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
      int state = BluetoothAdapter.STATE_OFF;

      BluetoothManager bluetoothManager = (BluetoothManager)
          registrar.activeContext().getSystemService(Context.BLUETOOTH_SERVICE);
      if (bluetoothManager != null) {
        BluetoothAdapter adapter = bluetoothManager.getAdapter();
        if (adapter != null) {
          state = adapter.getState();
        }
      }
      mReceiver.setEventSink(eventSink, state);
      IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
      registrar.activity().registerReceiver(mReceiver, filter);
    }

    @Override
    public void onCancel(Object o) {
      registrar.activity().unregisterReceiver(mReceiver);
    }
  };

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

  //region RANGING
  private EventChannel.StreamHandler rangingStreamHandler = new EventChannel.StreamHandler() {
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
      startRanging(o, eventSink);
    }

    @Override
    public void onCancel(Object o) {
      stopRanging();
    }
  };

  private void startRanging(Object o, EventChannel.EventSink eventSink) {
    Log.d(TAG, "START RANGING=" + o);
    if (o instanceof List) {
      //noinspection unchecked
      List<Object> list = (List<Object>) o;
      if (regionRanging == null) {
        regionRanging = new ArrayList<>();
      } else {
        regionRanging.clear();
      }
      for (Object object : list) {
        if (object instanceof Map) {
          //noinspection unchecked
          Region region = FlutterBeaconUtils.regionFromMap((Map<String, Object>) object);
          regionRanging.add(region);
        }
      }
    } else {
      eventSink.error("Beacon", "invalid region for ranging", null);
      return;
    }
    eventSinkRanging = eventSink;
    if (beaconManager!= null && !beaconManager.isBound(beaconConsumer)) {
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
  private EventChannel.StreamHandler monitoringStreamHandler = new EventChannel.StreamHandler() {
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
      //noinspection unchecked
      List<Object> list = (List<Object>) o;
      if (regionMonitoring == null) {
        regionMonitoring = new ArrayList<>();
      } else {
        regionMonitoring.clear();
      }
      for (Object object : list) {
        if (object instanceof Map) {
          //noinspection unchecked
          Region region = FlutterBeaconUtils.regionFromMap((Map<String, Object>) object);
          regionMonitoring.add(region);
        }
      }
    } else {
      eventSink.error("Beacon", "invalid region for monitoring", null);
      return;
    }
    eventSinkMonitoring = eventSink;
    if (beaconManager!= null && !beaconManager.isBound(beaconConsumer)) {
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

  private MonitorNotifier monitorNotifier = new MonitorNotifier() {
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
        ActivityCompat.requestPermissions(registrar.activity(), new String[]{
            Manifest.permission.ACCESS_COARSE_LOCATION
        }, REQUEST_CODE_LOCATION);
      } else {
        if (flutterResult != null) {
          flutterResult.success(true);
          flutterResult = null;
        }
      }
    } else {
      if (flutterResult != null) {
        flutterResult.error("Beacon", "bluetooth disabled", null);
        flutterResult = null;
      }
    }

    return bluetoothEnabled;
  }
  // endregion
}
