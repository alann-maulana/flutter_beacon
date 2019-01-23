//
//  FBMonitoringStreamHandler.m
//  flutter_beacon
//
//  Created by Alann Maulana on 23/01/19.
//

#import "FBMonitoringStreamHandler.h"
#import <FlutterBeaconPlugin.h>

@implementation FBMonitoringStreamHandler

- (instancetype) initWithFlutterBeaconPlugin:(FlutterBeaconPlugin*) instance {
    if (self = [super init]) {
        _instance = instance;
    }
    
    return self;
}

///------------------------------------------------------------
#pragma mark - Flutter Stream Handler
///------------------------------------------------------------

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    if (self.instance) {
        [self.instance stopMonitoringBeacon];
    }
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    if (self.instance) {
        self.instance.flutterEventSinkMonitoring = events;
        [self.instance startMonitoringBeaconWithCall:arguments];
    }
    return nil;
}

@end
