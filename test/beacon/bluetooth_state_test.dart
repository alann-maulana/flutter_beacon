import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bluetooth state initialization', () {
    final bluetoothState = BluetoothState.init(
      'VALUE',
      isAndroid: true,
      isIOS: true,
    );
    expect(bluetoothState.value, 'VALUE');
    expect(bluetoothState.isAndroid, isTrue);
    expect(bluetoothState.isIOS, isTrue);
  });

  test('bluetooth state must be equal', () {
    final stateA = BluetoothState.init(
      'VALUE',
      isAndroid: true,
      isIOS: false,
    );
    final stateB = BluetoothState.init(
      'VALUE',
      isAndroid: true,
      isIOS: false,
    );
    expect(stateA, stateB);
    expect(stateA.hashCode, stateB.hashCode);
    expect(stateA.value, stateB.value);
    expect(stateA.isAndroid, stateB.isAndroid);
    expect(stateA.isIOS, stateB.isIOS);
    expect(stateA.toString(), stateB.toString());
  });

  test('bluetooth state value', () {
    expect(BluetoothState.stateOff.value, 'STATE_OFF');
    expect(BluetoothState.stateTurningOff.value, 'STATE_TURNING_OFF');
    expect(BluetoothState.stateOn.value, 'STATE_ON');
    expect(BluetoothState.stateTurningOn.value, 'STATE_TURNING_ON');
    expect(BluetoothState.stateUnknown.value, 'STATE_UNKNOWN');
    expect(BluetoothState.stateResetting.value, 'STATE_RESETTING');
    expect(BluetoothState.stateUnsupported.value, 'STATE_UNSUPPORTED');
    expect(BluetoothState.stateUnauthorized.value, 'STATE_UNAUTHORIZED');
  });

  test('parse bluetooth state value', () {
    expect(BluetoothState.parse('STATE_OFF'), BluetoothState.stateOff);
    expect(BluetoothState.parse('STATE_TURNING_OFF'),
        BluetoothState.stateTurningOff);
    expect(BluetoothState.parse('STATE_ON'), BluetoothState.stateOn);
    expect(BluetoothState.parse('STATE_TURNING_ON'),
        BluetoothState.stateTurningOn);
    expect(BluetoothState.parse('STATE_UNKNOWN'), BluetoothState.stateUnknown);
    expect(
        BluetoothState.parse('STATE_RESETTING'), BluetoothState.stateResetting);
    expect(BluetoothState.parse('STATE_UNSUPPORTED'),
        BluetoothState.stateUnsupported);
    expect(BluetoothState.parse('STATE_UNAUTHORIZED'),
        BluetoothState.stateUnauthorized);
  });
}
