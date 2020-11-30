//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Enum class for showing state about bluetooth.
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

  /// The defined [String] value of the bluetooth state.
  final String value;

  /// This will `true` only if this bluetooth state suit Android system.
  final bool isAndroid;

  /// This will `true` only if this bluetooth state suit iOS system.
  final bool isIOS;

  /// Shows that bluetooth state is off.
  static const stateOff = BluetoothState.init(
    'STATE_OFF',
  );

  /// Shows that bluetooth state is turning off.
  ///
  /// Only for Android
  static const stateTurningOff = BluetoothState.init(
    'STATE_TURNING_OFF',
    isIOS: false,
  );

  /// Shows that bluetooth state is on.
  static const stateOn = BluetoothState.init(
    'STATE_ON',
  );

  /// Shows that bluetooth state is turning on.
  ///
  /// Only in Android
  static const stateTurningOn = BluetoothState.init(
    'STATE_TURNING_ON',
    isIOS: false,
  );

  /// Shows that bluetooth state is unknown. This is the default.
  static const stateUnknown = BluetoothState.init(
    'STATE_UNKNOWN',
  );

  /// Shows that bluetooth state is resetting.
  ///
  /// Only for iOS
  static const stateResetting = BluetoothState.init(
    'STATE_RESETTING',
    isAndroid: false,
  );

  /// Shows that bluetooth state is unsupported.
  static const stateUnsupported = BluetoothState.init(
    'STATE_UNSUPPORTED',
  );

  /// Shows that bluetooth state is unauthorized.
  ///
  /// Only for iOS
  static const stateUnauthorized = BluetoothState.init(
    'STATE_UNAUTHORIZED',
    isAndroid: false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothState &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          isAndroid == other.isAndroid &&
          isIOS == other.isIOS;

  @override
  int get hashCode => value.hashCode ^ isAndroid.hashCode ^ isIOS.hashCode;

  @override
  String toString() {
    return value;
  }
}
