//  Copyright (c) 2018 Alann Maulana.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Class for managing ranging region scanning.
class Region {

  /// The unique identifier of region.
  final String identifier;

  /// The proximity UUID of region.
  ///
  /// For Android, this value can be null.
  final String proximityUUID;

  /// The major number of region.
  ///
  /// For both Android and iOS, this value can be null.
  final int major;

  /// The minor number of region.
  ///
  /// For both Android and iOS, this value can be null.
  final int minor;

  /// Constructor for creating [Region] object.
  Region(
      {@required this.identifier,
      this.proximityUUID,
      this.major,
      this.minor}) : assert(Platform.isIOS && proximityUUID != null);

  /// Constructor for deserialize json [Map] into [Region] object.
  Region.fromJson(dynamic json)
      : identifier = json['identifier'],
        proximityUUID = json['proximityUUID'],
        major = json['major'],
        minor = json['minor'];

  /// Serialize [Region] object into json [Map].
  dynamic get toJson {
    final map = <String, dynamic>{
      'identifier': identifier,
    };

    if (proximityUUID != null) {
      map['proximityUUID'] = proximityUUID;
    }

    if (major != null) {
      map['major'] = major;
    }

    if (minor != null) {
      map['minor'] = minor;
    }

    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Region &&
              runtimeType == other.runtimeType &&
              identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;

}
