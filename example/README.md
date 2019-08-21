### Initializing Library

```dart
try {
  await flutterBeacon.initializeScanning;
} on PlatformException catch(e) {
  // library failed to initialize, check code and message
}
```

### Ranging beacons

```dart
final regions = <Region>[];

if (Platform.isIOS) {
  regions.add(Region(
      identifier: 'Apple Airlocate',
      proximityUUID: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0'));
} else {
  // android platform, it can ranging out of beacon that filter all of Proximity UUID
  regions.add(Region(identifier: 'com.beacon'));
}

// to start ranging beacons
_streamRanging = flutterBeacon.ranging(regions).listen((RangingResult result) {
  // result contains a region and list of beacons found
  // list can be empty if no matching beacons were found in range
});

// to stop ranging beacons
_streamRanging.cancel();
```

### Monitoring beacons

```dart
final regions = <Region>[];

if (Platform.isIOS) {
  regions.add(Region(
      identifier: 'Apple Airlocate',
      proximityUUID: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0'));
} else {
  // android platform, it can ranging out of beacon that filter all of Proximity UUID
  regions.add(Region(identifier: 'com.beacon'));
}

// to start monitoring beacons
_streamMonitoring = flutterBeacon.monitoring(regions).listen((MonitoringResult result) {
  // result contains a region, event type and event state
});

// to stop monitoring beacons
_streamMonitoring.cancel();
```
