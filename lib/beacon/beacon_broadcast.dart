//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Class for managing Beacon Broadcast object.
class BeaconBroadcast {
  /// The unique identifier of region.
  final String identifier;

  /// The proximity UUID of beacon.
  final String proximityUUID;

  /// The major value of beacon.
  final int major;

  /// The minor value of beacon.
  final int minor;

  /// The minor value of beacon.
  final int txPower;

  final AdvertisingMode advertisingMode;

  final AdvertisingTxPowerLevel advertisingTxPowerLevel;

  BeaconBroadcast({
    this.identifier = 'com.flutterBeacon',
    @required this.proximityUUID,
    @required this.major,
    @required this.minor,
    this.txPower,
    this.advertisingMode = AdvertisingMode.low,
    this.advertisingTxPowerLevel = AdvertisingTxPowerLevel.high,
  }) {
    if (Platform.isAndroid) {
      assert(advertisingMode != null);
      assert(advertisingTxPowerLevel != null);
    } else if (Platform.isIOS) {
      assert(identifier != null);
    }
  }

  /// Serialize current instance object into [Map].
  dynamic get toJson {
    final map = <String, dynamic>{
      'proximityUUID': proximityUUID,
      'major': major,
      'minor': minor,
      'txPower': txPower,
    };

    if (Platform.isAndroid) {
      map['advertisingMode'] = advertisingMode.index;
      map['advertisingTxPowerLevel'] = advertisingTxPowerLevel.index;
    } else if (Platform.isIOS) {
      map['identifier'] = identifier;
    }

    return map;
  }
}

enum AdvertisingMode { low, mid, high }

enum AdvertisingTxPowerLevel { ultraLow, low, mid, high }
