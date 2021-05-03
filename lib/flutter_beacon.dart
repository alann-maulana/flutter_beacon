//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

/// Flutter beacon library.
library flutter_beacon;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'beacon/authorization_status.dart';
part 'beacon/beacon.dart';
part 'beacon/beacon_broadcast.dart';
part 'beacon/bluetooth_state.dart';
part 'beacon/monitoring_result.dart';
part 'beacon/ranging_result.dart';
part 'beacon/region.dart';

/// Singleton instance for accessing scanning API.
final FlutterBeacon flutterBeacon = new FlutterBeacon._internal();

/// Provide iBeacon scanning API for both Android and iOS.
class FlutterBeacon {
  FlutterBeacon._internal();

  /// Method Channel used to communicate to native code.
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_beacon');

  /// Event Channel used to communicate to native code ranging beacons.
  static const EventChannel _rangingChannel =
      EventChannel('flutter_beacon_event');

  /// Event Channel used to communicate to native code monitoring beacons.
  static const EventChannel _monitoringChannel =
      EventChannel('flutter_beacon_event_monitoring');

  /// Event Channel used to communicate to native code to checking
  /// for bluetooth state changed.
  static const EventChannel _bluetoothStateChangedChannel =
      EventChannel('flutter_bluetooth_state_changed');

  /// Event Channel used to communicate to native code to checking
  /// for bluetooth state changed.
  static const EventChannel _authorizationStatusChangedChannel =
      EventChannel('flutter_authorization_status_changed');

  /// This information does not change from call to call. Cache it.
  Stream<BluetoothState>? _onBluetoothState;

  /// This information does not change from call to call. Cache it.
  Stream<AuthorizationStatus>? _onAuthorizationStatus;

  /// Initialize scanning API.
  Future<bool> get initializeScanning async {
    final result = await _methodChannel.invokeMethod('initialize');

    if (result is bool) {
      return result;
    } else if (result is int) {
      return result == 1;
    }

    return result;
  }

  /// Initialize scanning API and check required permissions.
  ///
  /// For Android, it will check whether Bluetooth is enabled,
  /// allowed to access location services and check
  /// whether location services is enabled.
  /// For iOS, it will check whether Bluetooth is enabled,
  /// requestWhenInUse or requestAlways location services and check
  /// whether location services is enabled.
  Future<bool> get initializeAndCheckScanning async {
    final result = await _methodChannel.invokeMethod('initializeAndCheck');

    if (result is bool) {
      return result;
    }

    return result == 1;
  }

  /// Set the default AuthorizationStatus to use in requesting location authorization.
  /// For iOS, this can be either [AuthorizationStatus.whenInUse] or [AuthorizationStatus.always].
  /// For Android, this is not used.
  ///
  /// This method should be called very early to have an effect,
  /// before any of the other initializeScanning or authorizationStatus getters.
  ///
  Future<bool> setLocationAuthorizationTypeDefault(
      AuthorizationStatus authorizationStatus) async {
    return await _methodChannel.invokeMethod(
        'setLocationAuthorizationTypeDefault', authorizationStatus.value);
  }

  /// Check for the latest [AuthorizationStatus] from device.
  ///
  /// For Android, this will return [AuthorizationStatus.allowed], [AuthorizationStatus.denied] or [AuthorizationStatus.notDetermined].
  Future<AuthorizationStatus> get authorizationStatus async {
    final status = await _methodChannel.invokeMethod('authorizationStatus');
    return AuthorizationStatus.parse(status);
  }

  /// Return `true` when location service is enabled, otherwise `false`.
  Future<bool> get checkLocationServicesIfEnabled async {
    final result =
        await _methodChannel.invokeMethod('checkLocationServicesIfEnabled');

    if (result is bool) {
      return result;
    }

    return result == 1;
  }

  /// Check for the latest [BluetoothState] from device.
  Future<BluetoothState> get bluetoothState async {
    final status = await _methodChannel.invokeMethod('bluetoothState');
    return BluetoothState.parse(status);
  }

  /// Request an authorization to the device.
  ///
  /// For Android, this will request a permission of `Manifest.permission.ACCESS_COARSE_LOCATION`.
  /// For iOS, this will send a request `CLLocationManager#requestAlwaysAuthorization`.
  Future<bool> get requestAuthorization async {
    final result = await _methodChannel.invokeMethod('requestAuthorization');

    if (result is bool) {
      return result;
    }

    return result == 1;
  }

  /// Request to open Bluetooth Settings from device.
  ///
  /// For iOS, this will does nothing because of private method.
  Future<bool> get openBluetoothSettings async {
    final result = await _methodChannel.invokeMethod('openBluetoothSettings');

    if (result is bool) {
      return result;
    }

    return result == 1;
  }

  /// Request to open Locations Settings from device.
  ///
  /// For iOS, this will does nothing because of private method.
  Future<bool> get openLocationSettings async {
    final result = await _methodChannel.invokeMethod('openLocationSettings');

    if (result is bool) {
      return result;
    }

    return result == 1;
  }

  /// Request to open Application Settings from device.
  ///
  /// For Android, this will does nothing.
  Future<bool> get openApplicationSettings async {
    final result = await _methodChannel.invokeMethod('openApplicationSettings');

    if (result is bool) {
      return result;
    }

    return result == 1;
  }

  /// Customize duration of the beacon scan on the Android Platform.
  Future<bool> setScanPeriod(int scanPeriod) async {
    return await _methodChannel
        .invokeMethod('setScanPeriod', {"scanPeriod": scanPeriod});
  }

  /// Customize duration spent not scanning between each scan cycle on the Android Platform.
  Future<bool> setBetweenScanPeriod(int scanPeriod) async {
    return await _methodChannel.invokeMethod(
        'setBetweenScanPeriod', {"betweenScanPeriod": scanPeriod});
  }

  /// Close scanning API.
  Future<bool> get close async {
    final result = await _methodChannel.invokeMethod('close');

    if (result is bool) {
      return result;
    }

    return result == 1;
  }

  /// Start ranging iBeacons with defined [List] of [Region]s.
  ///
  /// This will fires [RangingResult] whenever the iBeacons in range.
  Stream<RangingResult> ranging(List<Region> regions) {
    final list = regions.map((region) => region.toJson).toList();
    final Stream<RangingResult> onRanging = _rangingChannel
        .receiveBroadcastStream(list)
        .map((dynamic event) => RangingResult.from(event));
    return onRanging;
  }

  /// Start monitoring iBeacons with defined [List] of [Region]s.
  ///
  /// This will fires [MonitoringResult] whenever the iBeacons in range.
  Stream<MonitoringResult> monitoring(List<Region> regions) {
    final list = regions.map((region) => region.toJson).toList();
    final Stream<MonitoringResult> onMonitoring = _monitoringChannel
        .receiveBroadcastStream(list)
        .map((dynamic event) => MonitoringResult.from(event));
    return onMonitoring;
  }

  /// Start checking for bluetooth state changed.
  ///
  /// This will fires [BluetoothState] whenever bluetooth state changed.
  Stream<BluetoothState> bluetoothStateChanged() {
    if (_onBluetoothState == null) {
      _onBluetoothState = _bluetoothStateChangedChannel
          .receiveBroadcastStream()
          .map((dynamic event) => BluetoothState.parse(event));
    }
    return _onBluetoothState!;
  }

  /// Start checking for location service authorization status changed.
  ///
  /// This will fires [AuthorizationStatus] whenever authorization status changed.
  Stream<AuthorizationStatus> authorizationStatusChanged() {
    if (_onAuthorizationStatus == null) {
      _onAuthorizationStatus = _authorizationStatusChangedChannel
          .receiveBroadcastStream()
          .map((dynamic event) => AuthorizationStatus.parse(event));
    }
    return _onAuthorizationStatus!;
  }

  Future<void> startBroadcast(BeaconBroadcast params) async {
    await _methodChannel.invokeMethod('startBroadcast', params.toJson);
  }

  Future<void> stopBroadcast() async {
    await _methodChannel.invokeMethod('stopBroadcast');
  }

  Future<bool> isBroadcasting() async {
    final flag = await _methodChannel.invokeMethod('isBroadcasting');
    return flag == true || flag == 1;
  }

  Future<bool> isBroadcastSupported() async {
    final flag = await _methodChannel.invokeMethod('isBroadcastSupported');
    return flag == true || flag == 1;
  }
}
