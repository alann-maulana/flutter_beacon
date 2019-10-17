//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Class for managing ranging result from scanning iBeacon process.
class RangingResult {
  /// The [Region] of ranging result.
  final Region region;

  /// The [List] of [Beacon] detected of ranging result by [Region].
  final List<Beacon> beacons;

  /// Constructor for deserialize dynamic json into [RangingResult].
  RangingResult._from(dynamic json)
      : region = Region.fromJson(json['region']),
        beacons = Beacon.beaconFromArray(json['beacons']);

  @override
  String toString() {
    return 'RangingResult{"region": ${json.encode(region.toJson)}, "beacons": ${json.encode(Beacon.beaconArrayToJson(beacons))}}';
  }
}
