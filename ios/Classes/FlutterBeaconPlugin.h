#import <Flutter/Flutter.h>

@interface FlutterBeaconPlugin : NSObject<FlutterPlugin>

@property FlutterEventSink flutterEventSinkRanging;
@property FlutterEventSink flutterEventSinkMonitoring;

- (void) startRangingBeaconWithCall:(id)arguments;
- (void) stopRangingBeacon;
- (void) startMonitoringBeaconWithCall:(id)arguments;
- (void) stopMonitoringBeacon;

@end
