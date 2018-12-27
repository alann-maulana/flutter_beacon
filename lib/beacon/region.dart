part of flutter_beacon;

class Region {
  final String identifier;
  final String proximityUUID;
  final int major;
  final int minor;

  Region(
      {@required this.identifier,
      this.proximityUUID,
      this.major,
      this.minor}) : assert(Platform.isIOS && proximityUUID != null);

  Region.fromJson(dynamic json)
      : identifier = json['identifier'],
        proximityUUID = json['proximityUUID'],
        major = json['major'],
        minor = json['minor'];

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
