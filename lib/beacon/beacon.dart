part of flutter_beacon;

enum Proximity { unknown, immediate, near, far }

class Beacon {

  final String proximityUUID;
  final String macAddress;
  final int major;
  final int minor;
  final int rssi;
  final int txPower;
  final double accuracy;
  final Proximity _proximity;

  Beacon.fromJson(dynamic json)
      : proximityUUID = json['proximityUUID'],
        macAddress = json['macAddress'],
        major = json['major'],
        minor = json['minor'],
        rssi = _parseInt(json['rssi']),
        txPower = _parseInt(json['txPower']),
        accuracy = _parseDouble(json['accuracy']),
        _proximity = _parseProximity(json['proximity']);

  static double _parseDouble(dynamic data) {
    if (data is num) {
      return data;
    } else if (data is String) {
      return double.parse(data);
    }

    return 0.0;
  }

  static int _parseInt(dynamic data) {
    if (data is num) {
      return data;
    } else if (data is String) {
      return int.parse(data);
    }

    return 0;
  }

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

  static List<Beacon> beaconFromArray(dynamic beacons) {
    if (beacons is List) {
      return beacons.map((json) {
        return Beacon.fromJson(json);
      }).toList();
    }

    return null;
  }

  static dynamic beaconArrayToJson(List<Beacon> beacons) {
    return beacons.map((beacon) {
      return beacon.toJson;
    }).toList();
  }

  dynamic get toJson => <String, dynamic>{
        'proximityUUID': proximityUUID,
        'major': major,
        'minor': minor,
        'rssi': rssi ?? -1,
        'txPower': txPower ?? -1,
        'accuracy': accuracy,
        'proximity': proximity.toString()
      };

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
