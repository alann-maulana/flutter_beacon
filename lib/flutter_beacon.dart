//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

library flutter_beacon;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'beacon/authorization_status.dart';
part 'beacon/beacon.dart';
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
  Stream<RangingResult> _onRanging;

  /// This information does not change from call to call. Cache it.
  Stream<MonitoringResult> _onMonitoring;

  /// This information does not change from call to call. Cache it.
  Stream<BluetoothState> _onBluetoothState;

  /// This information does not change from call to call. Cache it.
  Stream<AuthorizationStatus> _onAuthorizationStatus;

  /// Initialize scanning API.
  Future<bool> get initializeScanning async {
    return await _methodChannel.invokeMethod('initialize');
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
    return await _methodChannel.invokeMethod('initializeAndCheck');
  }

  /// Check for the latest [AuthorizationStatus] from device.
  ///
  /// For Android, this will return between [AuthorizationStatus.allowed]
  /// or [AuthorizationStatus.denied] only.
  Future<AuthorizationStatus> get authorizationStatus async {
    final status = await _methodChannel.invokeMethod('authorizationStatus');
    return AuthorizationStatus.parse(status);
  }

  /// Return `true` when location service is enabled, otherwise `false`.
  Future<bool> get checkLocationServicesIfEnabled async {
    return await _methodChannel.invokeMethod('checkLocationServicesIfEnabled');
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
    return await _methodChannel.invokeMethod('requestAuthorization');
  }

  /// Request to open Bluetooth Settings from device.
  ///
  /// For iOS, this will does nothing because of private method.
  Future<bool> get openBluetoothSettings async {
    return await _methodChannel.invokeMethod('openBluetoothSettings');
  }

  /// Request to open Locations Settings from device.
  ///
  /// For iOS, this will does nothing because of private method.
  Future<bool> get openLocationSettings async {
    return await _methodChannel.invokeMethod('openLocationSettings');
  }

  /// Request to open Application Settings from device.
  ///
  /// For Android, this will does nothing.
  Future<bool> get openApplicationSettings async {
    return await _methodChannel.invokeMethod('openApplicationSettings');
  }

  /// Close scanning API.
  Future<bool> get close async {
    return await _methodChannel.invokeMethod('close');
  }

  /// Start ranging iBeacons with defined [List] of [Region]s.
  ///
  /// This will fires [RangingResult] whenever the iBeacons in range.
  Stream<RangingResult> ranging(List<Region> regions) {
    if (_onRanging == null) {
      final list = regions.map((region) => region.toJson).toList();
      _onRanging = _rangingChannel
          .receiveBroadcastStream(list)
          .map((dynamic event) => RangingResult.from(event));
    }
    return _onRanging;
  }

  /// Start monitoring iBeacons with defined [List] of [Region]s.
  ///
  /// This will fires [MonitoringResult] whenever the iBeacons in range.
  Stream<MonitoringResult> monitoring(List<Region> regions) {
    if (_onMonitoring == null) {
      final list = regions.map((region) => region.toJson).toList();
      _onMonitoring = _monitoringChannel
          .receiveBroadcastStream(list)
          .map((dynamic event) => MonitoringResult.from(event));
    }
    return _onMonitoring;
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
    return _onBluetoothState;
  }

  /// Start checking for location service authorization status changed.
  /// This stream only enabled on iOS only.
  ///
  /// This will fires [AuthorizationStatus] whenever authorization status changed.
  Stream<AuthorizationStatus> authorizationStatusChanged() {
    if (_onAuthorizationStatus == null) {
      _onAuthorizationStatus = _authorizationStatusChangedChannel
          .receiveBroadcastStream()
          .map((dynamic event) => AuthorizationStatus.parse(event));
    }
    return _onAuthorizationStatus;
  }
}
