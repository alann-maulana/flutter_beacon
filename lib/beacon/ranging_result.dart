part of flutter_beacon;

class RangingResult {
  final Region region;
  final List<Beacon> beacons;

  RangingResult.from(dynamic json)
      : region = Region.fromJson(json['region']),
        beacons = Beacon.beaconFromArray(json['beacons']);

  @override
    String toString() {
      return 'RangingResult{"region": ${json.encode(region.toJson)}, "beacons": ${json.encode(Beacon.beaconArrayToJson(beacons))}}';
    }
}
