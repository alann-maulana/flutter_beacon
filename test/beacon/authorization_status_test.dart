import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authorization initialization', () {
    final authorizationStatus = AuthorizationStatus.init(
      'VALUE',
      isAndroid: true,
      isIOS: true,
    );
    expect(authorizationStatus.value, 'VALUE');
    expect(authorizationStatus.isAndroid, isTrue);
    expect(authorizationStatus.isIOS, isTrue);
  });

  test('authorization value', () {
    expect(AuthorizationStatus.allowed.value, 'ALLOWED');
    expect(AuthorizationStatus.always.value, 'ALWAYS');
    expect(AuthorizationStatus.whenInUse.value, 'WHEN_IN_USE');
    expect(AuthorizationStatus.denied.value, 'DENIED');
    expect(AuthorizationStatus.restricted.value, 'RESTRICTED');
    expect(AuthorizationStatus.notDetermined.value, 'NOT_DETERMINED');
  });

  test('parse authorization value', () {
    expect(AuthorizationStatus.parse('ALLOWED'), AuthorizationStatus.allowed);
    expect(AuthorizationStatus.parse('ALWAYS'), AuthorizationStatus.always);
    expect(AuthorizationStatus.parse('WHEN_IN_USE'),
        AuthorizationStatus.whenInUse);
    expect(AuthorizationStatus.parse('DENIED'), AuthorizationStatus.denied);
    expect(AuthorizationStatus.parse('RESTRICTED'),
        AuthorizationStatus.restricted);
    expect(AuthorizationStatus.parse('NOT_DETERMINED'),
        AuthorizationStatus.notDetermined);
  });
}
