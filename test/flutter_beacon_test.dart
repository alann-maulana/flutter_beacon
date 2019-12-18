import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('flutter_beacon');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      final method = methodCall.method;
      if (method == 'initialize') {
        return true;
      }

      if (method == 'initializeAndCheck') {
        return true;
      }

      throw MissingPluginException(
          'No implementation found for method $method on channel ${channel.name}');
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('Initialize return "true"', () async {
    expect(
      await flutterBeacon.initializeScanning,
      true,
    );
  });

  test('InitializeAndCheck return "true"', () async {
    expect(
      await flutterBeacon.initializeAndCheckScanning,
      true,
    );
  });
}
