import 'dart:convert';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test('MonitoringEventType must equalTo "didEnterRegion', () {
    final map = {
      'region': {
        'identifier': 'Cubeacon',
        'proximityUUID': 'CB10023F-A318-3394-4199-A8730C7C1AEC'
      },
      'beacons': [
        {
          'proximityUUID': 'CB10023F-A318-3394-4199-A8730C7C1AEC',
          'major': 1,
          'minor': 1,
          'rssi': -59,
          'accuracy': 1.2,
          'proximity': 'near',
        },
        {
          'proximityUUID': 'CB10023F-A318-3394-4199-A8730C7C1AEC',
          'major': 2,
          'minor': 2,
          'rssi': -58,
          'accuracy': 0.8,
          'proximity': 'immediate',
        }
      ]
    };
    final enter = RangingResult.from(map);

    expect(enter.region, isNotNull);
    expect(enter.region.identifier, 'Cubeacon');
    expect(enter.region.proximityUUID, 'CB10023F-A318-3394-4199-A8730C7C1AEC');
    expect(enter.beacons, isNotEmpty);
    expect(enter.beacons.length, 2);
    expect(enter.toJson, map);
    expect(enter.toString(), json.encode(map));
  });
}
