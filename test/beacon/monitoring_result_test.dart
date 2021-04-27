import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test('MonitoringEventType must equalTo "didEnterRegion', () {
    final map = {
      'region': {
        'identifier': 'id',
        'proximityUUID': 'UUID',
      },
      'event': 'didEnterRegion',
    };
    final enter = MonitoringResult.from(map);

    expect(enter.region, isNotNull);
    expect(enter.region.identifier, 'id');
    expect(enter.region.proximityUUID, 'UUID');
    expect(enter.monitoringEventType, MonitoringEventType.didEnterRegion);
    expect(enter.toJson, map);
  });

  test('MonitoringEventType must equalTo "didExitRegion', () {
    final map = {
      'region': {
        'identifier': 'id',
        'proximityUUID': 'UUID',
      },
      'event': 'didExitRegion',
    };
    final enter = MonitoringResult.from(map);

    expect(enter.region, isNotNull);
    expect(enter.region.identifier, 'id');
    expect(enter.region.proximityUUID, 'UUID');
    expect(enter.monitoringEventType, MonitoringEventType.didExitRegion);
    expect(enter.toJson, map);
  });

  test('MonitoringEventType must equalTo "didDetermineStateForRegion', () {
    final map = {
      'region': {
        'identifier': 'id',
        'proximityUUID': 'UUID',
      },
      'state': 'unknown',
      'event': 'didDetermineStateForRegion',
    };
    final enter = MonitoringResult.from(map);

    expect(enter.region, isNotNull);
    expect(enter.region.identifier, 'id');
    expect(enter.region.proximityUUID, 'UUID');
    expect(enter.monitoringEventType,
        MonitoringEventType.didDetermineStateForRegion);
    expect(enter.monitoringState, MonitoringState.unknown);
    expect(enter.toJson, map);
  });

  test('MonitoringResult must throw', () {
    final map = {
      'region': {
        'identifier': 'id',
        'proximityUUID': 'UUID',
      },
      'state': 'unknown',
      'event': 'null',
    };

    expect(() => MonitoringResult.from(map), throwsException);
  });
}
