//  Copyright (c) 2018 Alann Maulana.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Enum for defining proximity.
enum Proximity { unknown, immediate, near, far }

/// Class for managing Beacon object.
class Beacon {

  /// The proximity UUID of beacon.
  final String proximityUUID;

  /// The mac address of beacon.
  ///
  /// From iOS this value will be null
  final String macAddress;

  /// The major value of beacon.
  final int major;

  /// The minor value of beacon.
  final int minor;

  /// The rssi value of beacon.
  final int rssi;

  /// The transmission power of beacon.
  ///
  /// From iOS this value will be null
  final int txPower;

  /// The accuracy of distance of beacon.
  final double accuracy;

  /// The proximity of beacon.
  final Proximity _proximity;

  /// Create beacon object from json.
  Beacon.fromJson(dynamic json)
      : proximityUUID = json['proximityUUID'],
        macAddress = json['macAddress'],
        major = json['major'],
        minor = json['minor'],
        rssi = _parseInt(json['rssi']),
        txPower = _parseInt(json['txPower']),
        accuracy = _parseDouble(json['accuracy']),
        _proximity = _parseProximity(json['proximity']);

  /// Parsing dynamic data into double.
  static double _parseDouble(dynamic data) {
    if (data is num) {
      return data;
    } else if (data is String) {
      return double.parse(data);
    }

    return 0.0;
  }

  /// Parsing dynamic data into integer.
  static int _parseInt(dynamic data) {
    if (data is num) {
      return data;
    } else if (data is String) {
      return int.parse(data);
    }

    return 0;
  }

  /// Parsing dynamic proximity into enum [Proximity].
  static dynamic _parseProximity(dynamic proximity) {
    if (proximity == 'unknown') {
      return Proximity.unknown;
    }

    if (proximity == 'immediate') {
      return Proximity.immediate;
    }

    if (proximity == 'near') {
      return Proximity.near;
    }

    if (proximity == 'far') {
      return Proximity.far;
    }

    return null;
  }

  /// Parsing array of [Map] into [List] of [Beacon].
  static List<Beacon> beaconFromArray(dynamic beacons) {
    if (beacons is List) {
      return beacons.map((json) {
        return Beacon.fromJson(json);
      }).toList();
    }

    return null;
  }

  /// Parsing [List] of [Beacon] into array of [Map].
  static dynamic beaconArrayToJson(List<Beacon> beacons) {
    return beacons.map((beacon) {
      return beacon.toJson;
    }).toList();
  }

  /// Serialize current instance object into [Map].
  dynamic get toJson => <String, dynamic>{
        'proximityUUID': proximityUUID,
        'major': major,
        'minor': minor,
        'rssi': rssi ?? -1,
        'txPower': txPower ?? -1,
        'accuracy': accuracy,
        'proximity': proximity.toString()
      };

  /// Return [Proximity] of beacon.
  Proximity get proximity {
    if (_proximity != null) {
      return _proximity;
    }

    if (accuracy == 0.0) {
      return Proximity.unknown;
    }

    if (accuracy <= 0.5) {
      return Proximity.immediate;
    }

    if (accuracy < 3.0) {
      return Proximity.near;
    }

    return Proximity.far;
  }
}
