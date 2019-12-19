//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

class BluetoothState {
  @visibleForTesting
  const BluetoothState.init(
    this.value, {
    this.isAndroid = true,
    this.isIOS = true,
  });

  @visibleForTesting
  factory BluetoothState.parse(dynamic state) {
    switch (state) {
      case "STATE_OFF":
        return stateOff;
      case "STATE_TURNING_OFF":
        return stateTurningOff;
      case "STATE_ON":
        return stateOn;
      case "STATE_TURNING_ON":
        return stateTurningOn;
      case "STATE_UNKNOWN":
        return stateUnknown;
      case "STATE_RESETTING":
        return stateResetting;
      case "STATE_UNSUPPORTED":
        return stateUnsupported;
      case "STATE_UNAUTHORIZED":
        return stateUnauthorized;
    }

    return stateUnknown;
  }

  final String value;
  final bool isAndroid;
  final bool isIOS;

  static const stateOff = BluetoothState.init(
    'STATE_OFF',
  );
  static const stateTurningOff = BluetoothState.init(
    'STATE_TURNING_OFF',
    isIOS: false,
  );
  static const stateOn = BluetoothState.init(
    'STATE_ON',
  );
  static const stateTurningOn = BluetoothState.init(
    'STATE_TURNING_ON',
    isIOS: false,
  );
  static const stateUnknown = BluetoothState.init(
    'STATE_UNKNOWN',
  );
  static const stateResetting = BluetoothState.init(
    'STATE_RESETTING',
    isAndroid: false,
  );
  static const stateUnsupported = BluetoothState.init(
    'STATE_UNSUPPORTED',
  );
  static const stateUnauthorized = BluetoothState.init(
    'STATE_UNAUTHORIZED',
    isAndroid: false,
  );
}
