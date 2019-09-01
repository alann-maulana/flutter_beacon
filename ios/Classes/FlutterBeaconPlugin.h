#import <Flutter/Flutter.h>

@interface FlutterBeaconPlugin : NSObject<FlutterPlugin>

@property FlutterEventSink flutterEventSinkRanging;
@property FlutterEventSink flutterEventSinkMonitoring;
@property FlutterEventSink flutterEventSinkBluetooth;

- (void) startRangingBeaconWithCall:(id)arguments;
- (void) stopRangingBeacon;
- (void) startMonitoringBeaconWithCall:(id)arguments;
- (void) stopMonitoringBeacon;

@end
