#import <Flutter/Flutter.h>

@class CBCentralManager;
@class CBCentralManagerDelegate;
@interface FlutterBeaconPlugin : NSObject<FlutterPlugin>

@property FlutterEventSink flutterEventSinkRanging;
@property FlutterEventSink flutterEventSinkMonitoring;
@property FlutterEventSink flutterEventSinkBluetooth;

- (void) initializeCentralManager;
- (void) startRangingBeaconWithCall:(id)arguments;
- (void) stopRangingBeacon;
- (void) startMonitoringBeaconWithCall:(id)arguments;
- (void) stopMonitoringBeacon;

@end
