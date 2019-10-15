//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

class AuthorizationStatus {
  final String value;
  final bool isAndroid;
  final bool isIOS;

  const AuthorizationStatus._(
    this.value, {
    this.isAndroid,
    this.isIOS,
  });

  factory AuthorizationStatus.parse(String value) {
    switch (value) {
      case 'ALLOWED':
        return allowed;
      case 'ALWAYS':
        return always;
      case 'WHEN_IN_USER':
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

  static const AuthorizationStatus allowed = AuthorizationStatus._(
    'ALLOWED',
    isAndroid: true,
    isIOS: false,
  );

  static const AuthorizationStatus always = AuthorizationStatus._(
    'ALWAYS',
    isAndroid: false,
    isIOS: true,
  );

  static const AuthorizationStatus whenInUse = AuthorizationStatus._(
    'WHEN_IN_USER',
    isAndroid: false,
    isIOS: true,
  );

  static const AuthorizationStatus denied = AuthorizationStatus._(
    'DENIED',
    isAndroid: true,
    isIOS: true,
  );

  static const AuthorizationStatus restricted = AuthorizationStatus._(
    'RESTRICTED',
    isAndroid: false,
    isIOS: true,
  );

  static const AuthorizationStatus notDetermined = AuthorizationStatus._(
    'NOT_DETERMINED',
    isAndroid: false,
    isIOS: true,
  );
}
