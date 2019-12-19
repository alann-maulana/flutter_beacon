import 'dart:convert';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test('constructor test must be equal', () {
    final map = {
      'identifier': 'ID',
      'proximityUUID': 'UUID',
      'major': 1,
      'minor': 2,
    };
    final region = Region.fromJson(map);

    expect(region.identifier, 'ID');
    expect(region.proximityUUID, 'UUID');
    expect(region.major, 1);
    expect(region.minor, 2);
    expect(region.toJson, map);
    expect(region.toString(), json.encode(map));
  });

  test('two regions must be equal', () {
    final region1 = Region.fromJson({
      'identifier': 'ID',
      'proximityUUID': 'UUID',
      'major': '1',
      'minor': '2',
    });
    final region2 = Region(
      identifier: 'ID',
      proximityUUID: 'UUID',
      major: 1,
      minor: 2,
    );

    expect(region1.identifier, region2.identifier);
    expect(region1.proximityUUID, region2.proximityUUID);
    expect(region1.major, region2.major);
    expect(region1.minor, region2.minor);
    expect(region1 == region2, isTrue);
    expect(region1.hashCode == region2.hashCode, isTrue);
  });
}
