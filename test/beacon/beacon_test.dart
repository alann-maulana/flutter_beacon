import 'dart:convert';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test('main constructor must be equal', () {
    const beacon = const Beacon(
      proximityUUID: 'UUID',
      macAddress: 'MAC-ADDRESS',
      major: 1,
      minor: 2,
      rssi: -60,
      txPower: -59,
      accuracy: 0.0,
    );

    expect(beacon.proximityUUID, 'UUID');
    expect(beacon.macAddress, 'MAC-ADDRESS');
    expect(beacon.major, 1);
    expect(beacon.minor, 2);
    expect(beacon.rssi, -60);
    expect(beacon.txPower, -59);
    expect(beacon.accuracy, 0.0);
    expect(beacon.proximity, Proximity.unknown);

    const beacon2 = const Beacon(
      accuracy: 0.4,
      proximityUUID: 'UUID',
      major: 1,
      minor: 2,
      txPower: -59,
    );
    expect(beacon2.proximity, Proximity.immediate);

    const beacon3 = const Beacon(
      accuracy: 2.9,
      proximityUUID: 'UUID',
      major: 1,
      minor: 2,
      txPower: -59,
      rssi: null,
    );
    expect(beacon3.proximity, Proximity.near);
    expect(beacon3.rssi, -1);
  });

  test('constructor from json must be equal', () {
    final beacon = Beacon.fromJson({
      'proximityUUID': 'UUID',
      'macAddress': 'MAC-ADDRESS',
      'major': 1,
      'minor': 2,
      'rssi': '-60',
      'txPower': '-59',
      'accuracy': '1.23',
      'proximity': 'far',
    });

    expect(beacon.proximityUUID, 'UUID');
    expect(beacon.macAddress, 'MAC-ADDRESS');
    expect(beacon.major, 1);
    expect(beacon.minor, 2);
    expect(beacon.rssi, -60);
    expect(beacon.txPower, -59);
    expect(beacon.accuracy, 1.23);
  });

  test('beacon must be equal', () {
    final beacon1 = Beacon.fromJson({
      'proximityUUID': 'UUID',
      'macAddress': 'MAC-ADDRESS',
      'major': 1,
      'minor': 2,
      'rssi': '-60',
      'txPower': '-59',
      'accuracy': '1.23',
      'proximity': 'far',
    });
    final beacon2 = Beacon.fromJson({
      'proximityUUID': 'UUID',
      'macAddress': 'MAC-ADDRESS',
      'major': 1,
      'minor': 2,
      'rssi': '-60',
      'txPower': '-59',
      'accuracy': '1.23',
      'proximity': 'far',
    });

    expect(beacon1 == beacon2, isTrue);
    expect(beacon1.hashCode == beacon2.hashCode, isTrue);
  });

  test('parsing beacon array must be empty', () {
    expect(Beacon.beaconFromArray(Object()).isEmpty, isTrue);
  });

  test('parsing beacon array length must be equal to "2"', () {
    final beacons = [
      Beacon.fromJson({
        'proximityUUID': 'UUID',
        'macAddress': 'MAC-ADDRESS',
        'major': 1,
        'minor': 2,
        'rssi': '-60',
        'txPower': '-59',
        'accuracy': '1.23',
        'proximity': 'far',
      }),
      Beacon.fromJson({
        'proximityUUID': 'UUID',
        'macAddress': 'MAC-ADDRESS',
        'major': 1,
        'minor': 2,
        'rssi': '-60',
        'txPower': '-59',
        'accuracy': '1.23',
        'proximity': 'far',
      }),
    ];
    expect(Beacon.beaconArrayToJson(beacons) is List<dynamic>, isTrue);
    expect(
        Beacon.beaconFromArray(Beacon.beaconArrayToJson(beacons))
            is List<Beacon>,
        isTrue);
  });

  test('beacon json must be equal', () {
    final beacon = Beacon.fromJson({
      'macAddress': 'MAC',
      'proximityUUID': 'UUID',
      'major': 1,
      'minor': 2,
      'rssi': -60,
      'accuracy': 1.23,
      'proximity': 'far',
    });
    final beacon2 = Beacon.fromJson({
      'macAddress': 'MAC',
      'proximityUUID': 'UUID',
      'major': 1,
      'minor': 2,
      'rssi': -60,
      'accuracy': 1.23,
      'proximity': 'far',
    });

    expect(beacon, beacon2);
    expect(beacon.hashCode, beacon2.hashCode);
    expect(beacon.toJson, {
      'macAddress': 'MAC',
      'proximityUUID': 'UUID',
      'major': 1,
      'minor': 2,
      'rssi': -60,
      'accuracy': 1.23,
      'proximity': 'far',
    });
    expect(
        beacon.toString(),
        json.encode({
          'proximityUUID': 'UUID',
          'major': 1,
          'minor': 2,
          'rssi': -60,
          'accuracy': 1.23,
          'proximity': 'far',
          'macAddress': 'MAC',
        }));
  });
}
