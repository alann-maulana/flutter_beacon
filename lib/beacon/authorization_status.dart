//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Enum class for showing status about authorization.
class AuthorizationStatus {
  /// The defined [String] value of the authorization status.
  final String value;

  /// This will `true` only if this authorization status suit Android system.
  final bool isAndroid;

  /// This will `true` only if this authorization status suit iOS system.
  final bool isIOS;

  @visibleForTesting
  const AuthorizationStatus.init(
    this.value, {
    this.isAndroid = false,
    this.isIOS = false,
  });

  @visibleForTesting
  factory AuthorizationStatus.parse(String value) {
    switch (value) {
      case 'ALLOWED':
        return allowed;
      case 'ALWAYS':
        return always;
      case 'WHEN_IN_USE':
        return whenInUse;
      case 'DENIED':
        return denied;
      case 'RESTRICTED':
        return restricted;
      case 'NOT_DETERMINED':
        return notDetermined;
    }

    throw Exception('invalid authorization status $value');
  }

  /// Shows that user allowed the authorization.
  ///
  /// Only for Android
  static const AuthorizationStatus allowed = AuthorizationStatus.init(
    'ALLOWED',
    isAndroid: true,
    isIOS: false,
  );

  /// Shows that user always authorize app.
  ///
  /// Only for iOS
  static const AuthorizationStatus always = AuthorizationStatus.init(
    'ALWAYS',
    isAndroid: false,
    isIOS: true,
  );

  /// Shows that user authorize when in use app.
  ///
  /// Only for iOS
  static const AuthorizationStatus whenInUse = AuthorizationStatus.init(
    'WHEN_IN_USE',
    isAndroid: false,
    isIOS: true,
  );

  /// Shows that user denied authorization request.
  static const AuthorizationStatus denied = AuthorizationStatus.init(
    'DENIED',
    isAndroid: true,
    isIOS: true,
  );

  /// Shows that authorization has been restricted by system.
  ///
  /// Only for iOS
  static const AuthorizationStatus restricted = AuthorizationStatus.init(
    'RESTRICTED',
    isAndroid: false,
    isIOS: true,
  );

  /// Shows that authorization has not been determined by user.
  ///
  static const AuthorizationStatus notDetermined = AuthorizationStatus.init(
    'NOT_DETERMINED',
    isAndroid: true,
    isIOS: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorizationStatus &&
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
