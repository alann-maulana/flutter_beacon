# flutter_beacon

[![](/pub/v/flutter_beacon.svg)](https://github.com/alann-maulana/flutter_beacon) [![](/github/license/alann-maulana/flutter_beacon.svg)](https://github.com/alann-maulana/flutter_beacon/blob/master/LICENSE)

[Flutter plugin](https://pub.dartlang.org/packages/flutter_beacon/) to work with iBeacons.  

An hybrid iBeacon scanner SDK for Flutter plugin. Supports Android API 18+ and iOS 8+.

Features:

* Automatic permission management
* Ranging iBeacons  
* Monitoring iBeacons

## Installation

Add to pubspec.yaml:

```yaml
dependencies:
  flutter_beacon: ^0.2.1
```

### Setup specific for Android

Nothing.

### Setup specific for iOS

In order to use beacons related features, apps are required to ask the location permission. It's a two step process:

1. Declare the permission the app requires in configuration files
2. Request the permission to the user when app is running (the plugin can handle this automatically)

The needed permissions in iOS is `when in use`.

For more details about what you can do with each permission, see:  
https://developer.apple.com/documentation/corelocation/choosing_the_authorization_level_for_location_services

Permission must be declared in `ios/Runner/Info.plist`:

```xml
<dict>
  <!-- When in use -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Reason why app needs location</string>
  <!-- Always -->
  <!-- for iOS 11 + -->
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>Reason why app needs location</string>
  <!-- for iOS 9/10 -->
  <key>NSLocationAlwaysUsageDescription</key>
  <string>Reason why app needs location</string>
</dict>
```

## How-to

Ranging APIs are designed as reactive streams.  

* The first subscription to the stream will start the ranging

### Initializing Library

```dart
try {
  await flutterBeacon.initializeScanning;
} on PlatformException {
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

flutterBeacon.ranging(regions).listen((RangingResult result) {
  // result contains a region and list of beacons found
  // list can be empty if no matching beacons were found in range
});
```

## Under the hood

* iOS uses native iOS CoreLocation
* Android uses the third-party library [android-beacon-library](https://github.com/AltBeacon/android-beacon-library) (Apache License 2.0)

# Author

Flutter Beacon plugin is developed by Alann Maulana. You can contact me at <alann.maulana@outlook.com>.


## License

Apache License 2.0