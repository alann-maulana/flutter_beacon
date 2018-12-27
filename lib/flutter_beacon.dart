//  Copyright (c) 2018 Alann Maulana.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

library flutter_beacon;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'beacon/beacon.dart';
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

  /// Event Channel used to communicate to native code.
  static const EventChannel _rangingChannel =
      EventChannel('flutter_beacon_event');

  /// This information does not change from call to call. Cache it.
  Stream<RangingResult> _onRanging;

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
}
