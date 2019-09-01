//  Copyright (c) 2018 Alann Maulana.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

class BluetoothState {
  final String value;
  final bool isAndroid;
  final bool isIOS;

  static const stateOff = BluetoothState._(
    'STATE_OFF',
  );
  static const stateTurningOff = BluetoothState._(
    'STATE_TURNING_OFF',
    isIOS: false,
  );
  static const stateOn = BluetoothState._(
    'STATE_ON',
  );
  static const stateTurningOn = BluetoothState._(
    'STATE_TURNING_ON',
    isIOS: false,
  );
  static const stateUnknown = BluetoothState._(
    'STATE_UNKNOWN',
  );
  static const stateResetting = BluetoothState._(
    'STATE_RESETTING',
    isAndroid: false,
  );
  static const stateUnsupported = BluetoothState._(
    'STATE_UNSUPPORTED',
  );
  static const stateUnauthorized = BluetoothState._(
    'STATE_UNAUTHORIZED',
    isAndroid: false,
  );

  const BluetoothState._(
    this.value, {
    this.isAndroid = true,
    this.isIOS = true,
  });

  static BluetoothState parse(dynamic state) {
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
}
