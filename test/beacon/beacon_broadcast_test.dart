import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test('main constructor must be equal', () {
    final beacon = BeaconBroadcast(
      proximityUUID: 'UUID',
      major: 1,
      minor: 2,
      identifier: 'id',
      txPower: -58,
      advertisingMode: AdvertisingMode.high,
      advertisingTxPowerLevel: AdvertisingTxPowerLevel.low,
    );

    expect(beacon.proximityUUID, 'UUID');
    expect(beacon.major, 1);
    expect(beacon.minor, 2);
    expect(beacon.identifier, 'id');
    expect(beacon.txPower, -58);
    expect(beacon.advertisingMode, AdvertisingMode.high);
    expect(beacon.advertisingTxPowerLevel, AdvertisingTxPowerLevel.low);
    expect(beacon.toJson, isMap);
  });
}
