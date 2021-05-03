import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('flutter_beacon');
  const MethodChannel rangingChannel = MethodChannel('flutter_beacon_event');
  const MethodChannel monitoringChannel =
      MethodChannel('flutter_beacon_event_monitoring');
  const MethodChannel bluetoothChannel =
      MethodChannel('flutter_bluetooth_state_changed');
  const MethodChannel authorizationChannel =
      MethodChannel('flutter_authorization_status_changed');

  setUpAll(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      final method = methodCall.method;
      if (method == 'initialize') {
        return true;
      }

      if (method == 'initializeAndCheck') {
        return true;
      }

      if (method == 'authorizationStatus') {
        return AuthorizationStatus.allowed.value;
      }

      if (method == 'checkLocationServicesIfEnabled') {
        return true;
      }

      if (method == 'bluetoothState') {
        return BluetoothState.stateOn.value;
      }

      if (method == 'requestAuthorization') {
        return true;
      }

      if (method == 'openBluetoothSettings') {
        return true;
      }

      if (method == 'openLocationSettings') {
        return true;
      }

      if (method == 'openApplicationSettings') {
        return true;
      }

      if (method == 'close') {
        return true;
      }

      if (method == 'isBroadcasting') {
        return false;
      }

      if (method == 'isBroadcastSupported') {
        return true;
      }

      if (method == 'setScanPeriod') {
        return true;
      }

      if (method == 'setBetweenScanPeriod') {
        return true;
      }

      throw MissingPluginException(
          'No implementation found for method $method on channel ${channel.name}');
    });

    rangingChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      final args = methodCall.arguments;
      if (args is List) {
        if (args.isEmpty) {
          throw PlatformException(
              code: 'error', message: 'region ranging is empty');
        }
        List<Region> regions = args.map((arg) {
          return Region.fromJson(arg);
        }).toList();

        ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
          rangingChannel.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'region': regions.first.toJson,
            'beacons': [
              {
                'proximityUUID': regions.first.proximityUUID,
                'major': regions.first.major == null ? 1 : regions.first.major,
                'minor': regions.first.minor == null ? 1 : regions.first.minor,
                'rssi': -59,
                'accuracy': 1.2,
                'proximity': 'near',
              },
              {
                'proximityUUID': regions.first.proximityUUID,
                'major': regions.first.major == null ? 2 : regions.first.major,
                'minor': regions.first.minor == null ? 2 : regions.first.minor,
                'rssi': -58,
                'accuracy': 0.8,
                'proximity': 'immediate',
              }
            ]
          }),
          (ByteData? data) {},
        );
        return;
      }

      throw PlatformException(code: 'error', message: 'invalid region ranging');
    });

    monitoringChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      final args = methodCall.arguments;

      if (args is List) {
        if (args.isEmpty) {
          throw PlatformException(
              code: 'error', message: 'region monitoring is empty');
        }
        List<Region> regions = args.map((arg) {
          return Region.fromJson(arg);
        }).toList();

        regions.forEach((region) {
          dynamic result;
          if (region.identifier == 'onEnter') {
            result = {
              'region': region.toJson,
              'event': 'didEnterRegion',
            };
          } else if (region.identifier == 'onExit') {
            result = {
              'region': region.toJson,
              'event': 'didExitRegion',
            };
          } else if (region.identifier == 'onDetermine') {
            result = {
              'region': region.toJson,
              'event': 'didDetermineStateForRegion',
              'state': 'UNKNOWN',
            };
          }

          if (result != null) {
            ServicesBinding.instance!.defaultBinaryMessenger
                .handlePlatformMessage(
              monitoringChannel.name,
              const StandardMethodCodec().encodeSuccessEnvelope(result),
              (ByteData? data) {},
            );
          }
        });
        return;
      }

      throw PlatformException(
          code: 'error', message: 'invalid region monitoring');
    });

    bluetoothChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        bluetoothChannel.name,
        const StandardMethodCodec().encodeSuccessEnvelope('STATE_ON'),
        (ByteData? data) {},
      );
    });

    authorizationChannel
        .setMockMethodCallHandler((MethodCall methodCall) async {
      ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        authorizationChannel.name,
        const StandardMethodCodec().encodeSuccessEnvelope('ALLOWED'),
        (ByteData? data) {},
      );
    });
  });

  tearDownAll(() {
    channel.setMockMethodCallHandler(null);
    rangingChannel.setMockMethodCallHandler(null);
    monitoringChannel.setMockMethodCallHandler(null);
    bluetoothChannel.setMockMethodCallHandler(null);
    authorizationChannel.setMockMethodCallHandler(null);
  });

  group('Method channel', () {
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

    test('AuthorizationStatus return "allowed"', () async {
      expect(
        await flutterBeacon.authorizationStatus,
        AuthorizationStatus.allowed,
      );
    });

    test('CheckLocationServicesIfEnabled return "true"', () async {
      expect(
        await flutterBeacon.checkLocationServicesIfEnabled,
        true,
      );
    });

    test('BluetoothState return "stateOn"', () async {
      expect(
        await flutterBeacon.bluetoothState,
        BluetoothState.stateOn,
      );
    });

    test('RequestAuthorization return "true"', () async {
      expect(
        await flutterBeacon.requestAuthorization,
        true,
      );
    });

    test('OpenBluetoothSettings return "true"', () async {
      expect(
        await flutterBeacon.openBluetoothSettings,
        true,
      );
    });

    test('OpenLocationSettings return "true"', () async {
      expect(
        await flutterBeacon.openLocationSettings,
        true,
      );
    });

    test('OpenApplicationSettings return "true"', () async {
      expect(
        await flutterBeacon.openApplicationSettings,
        true,
      );
    });

    test('Close return "true"', () async {
      expect(
        await flutterBeacon.close,
        true,
      );
    });

    test('OpenLocationSettings return "true"', () async {
      expect(
        await flutterBeacon.openLocationSettings,
        true,
      );
    });

    test('SetScanPeriod return "true"', () async {
      expect(
        await flutterBeacon.setScanPeriod(1000),
        true,
      );
    });

    test('SetBetweenScanPeriod return "true"', () async {
      expect(
        await flutterBeacon.setBetweenScanPeriod(400),
        true,
      );
    });
  });

  group('Event channel - ranging', () {
    test('didRangeBeaconsInRegion', () async {
      final regions = <Region>[
        Region.fromJson({
          'identifier': 'Cubeacon',
          'proximityUUID': 'CB10023F-A318-3394-4199-A8730C7C1AEC'
        }),
      ];
      final result = await flutterBeacon.ranging(regions).first;
      expect(result.region, isNotNull);
      expect(result.region.identifier, 'Cubeacon');
      expect(
          result.region.proximityUUID, 'CB10023F-A318-3394-4199-A8730C7C1AEC');
      expect(result.beacons, isNotEmpty);
      expect(result.beacons.length, 2);
    });
  });

  group('Event channel - monitoring', () {
    late Stream<MonitoringResult> stream;

    setUpAll(() {
      final regions = <Region>[
        Region.fromJson({
          'identifier': 'onEnter',
          'proximityUUID': 'CB10023F-A318-3394-4199-A8730C7C1AEC',
          'major': 1,
          'minor': 1,
        }),
        Region.fromJson({
          'identifier': 'onExit',
          'proximityUUID': 'CB10023F-A318-3394-4199-A8730C7C1AEC',
          'major': 2,
          'minor': 2,
        }),
        Region.fromJson({
          'identifier': 'onDetermine',
          'proximityUUID': 'CB10023F-A318-3394-4199-A8730C7C1AEC',
          'major': 3,
          'minor': 3,
        }),
      ];

      stream = flutterBeacon.monitoring(regions);
    });

    test('didEnterRegion', () async {
      final result = await stream.first;

      expect(result.region, isNotNull);
      expect(result.region.identifier, 'onEnter');
      expect(
          result.region.proximityUUID, 'CB10023F-A318-3394-4199-A8730C7C1AEC');
      expect(result.region.major, 1);
      expect(result.region.minor, 1);
      expect(result.monitoringState, isNull);
      expect(result.monitoringEventType, MonitoringEventType.didEnterRegion);
    });

    test('didExitRegion', () async {
      final result = await stream.elementAt(2);

      expect(result.region, isNotNull);
      expect(result.region.identifier, 'onExit');
      expect(
          result.region.proximityUUID, 'CB10023F-A318-3394-4199-A8730C7C1AEC');
      expect(result.region.major, 2);
      expect(result.region.minor, 2);
      expect(result.monitoringState, isNull);
      expect(result.monitoringEventType, MonitoringEventType.didExitRegion);
    });

    test('didDetermineStateForRegion', () async {
      final result = await stream.elementAt(3);

      expect(result.region, isNotNull);
      expect(result.region.identifier, 'onDetermine');
      expect(
          result.region.proximityUUID, 'CB10023F-A318-3394-4199-A8730C7C1AEC');
      expect(result.region.major, 3);
      expect(result.region.minor, 3);
      expect(result.monitoringState, MonitoringState.unknown);
      expect(result.monitoringEventType,
          MonitoringEventType.didDetermineStateForRegion);
    });
  });

  group('Event channel - bluetooth state', () {
    test('bluetoothStateChanged', () async {
      final result = await flutterBeacon.bluetoothStateChanged().first;
      expect(result.value, 'STATE_ON');
    });
  });

  group('Event channel - authorization status', () {
    test('authorizationStatusChanged', () async {
      final result = await flutterBeacon.authorizationStatusChanged().first;
      expect(result.value, 'ALLOWED');
    });
  });

  group('Event channel - broadcast', () {
    test('isBroadcastSupported', () async {
      final result = await flutterBeacon.isBroadcastSupported();
      expect(result, true);
    });

    test('isBroadcasting', () async {
      final result = await flutterBeacon.isBroadcasting();
      expect(result, false);
    });
  });
}
