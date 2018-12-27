library flutter_beacon;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'beacon/beacon.dart';
part 'beacon/ranging_result.dart';
part 'beacon/region.dart';

final FlutterBeacon flutterBeacon = new FlutterBeacon._internal();

class FlutterBeacon {
  FlutterBeacon._internal();

  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_beacon');

  static const EventChannel _rangingChannel =
      EventChannel('flutter_beacon_event');

  Stream<RangingResult> _onRanging;

  Future<void> get initializeScanning async {
    await _methodChannel.invokeMethod('initialize');
  }

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
