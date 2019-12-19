//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

class AuthorizationStatus {
  final String value;
  final bool isAndroid;
  final bool isIOS;

  @visibleForTesting
  const AuthorizationStatus.init(
    this.value, {
    this.isAndroid,
    this.isIOS,
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

    return null;
  }

  static const AuthorizationStatus allowed = AuthorizationStatus.init(
    'ALLOWED',
    isAndroid: true,
    isIOS: false,
  );

  static const AuthorizationStatus always = AuthorizationStatus.init(
    'ALWAYS',
    isAndroid: false,
    isIOS: true,
  );

  static const AuthorizationStatus whenInUse = AuthorizationStatus.init(
    'WHEN_IN_USE',
    isAndroid: false,
    isIOS: true,
  );

  static const AuthorizationStatus denied = AuthorizationStatus.init(
    'DENIED',
    isAndroid: true,
    isIOS: true,
  );

  static const AuthorizationStatus restricted = AuthorizationStatus.init(
    'RESTRICTED',
    isAndroid: false,
    isIOS: true,
  );

  static const AuthorizationStatus notDetermined = AuthorizationStatus.init(
    'NOT_DETERMINED',
    isAndroid: false,
    isIOS: true,
  );
}
