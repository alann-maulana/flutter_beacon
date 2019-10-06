//  Copyright (c) 2018 Alann Maulana.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

library flutter_beacon;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// This information does not change from call to call. Cache it.
  Stream<RangingResult> _onRanging;

  /// This information does not change from call to call. Cache it.
  Stream<MonitoringResult> _onMonitoring;

  /// This information does not change from call to call. Cache it.
  Stream<BluetoothState> _onBluetoothState;

  /// Initialize scanning API.
  ///
  /// For Android, it will check whether Bluetooth is enabled,
  /// allowed to access location services and check
  /// whether location services is enabled.
  ///
  /// For iOS, it will check whether Bluetooth is enabled,
  /// requestWhenInUse location services and check
  /// whether location services is enabled.
  Future<void> get initializeScanning async {
    await _methodChannel.invokeMethod('initialize');
  }

  Future<void> get requestAuthorization async {
    await _methodChannel.invokeMethod('requestAuthorization');
  }

  Future<void> get openSettings async {
    await _methodChannel.invokeMethod('openSettings');
  }

  /// Close scanning API.
  Future<void> get close async {
    await _methodChannel.invokeMethod('close');
  }

  /// Start ranging iBeacons with defined [List] of [Region]s.
  ///
  /// This will fires [RangingResult] whenever the iBeacons in range.
  Stream<RangingResult> ranging(List<Region> regions) {
    if (_onRanging == null) {
      final list = regions.map((region) => region.toJson).toList();
      _onRanging = _rangingChannel
          .receiveBroadcastStream(list)
          .map((dynamic event) => RangingResult._from(event));
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
          .map((dynamic event) => MonitoringResult._from(event));
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
}
