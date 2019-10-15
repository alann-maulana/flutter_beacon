//
//  FBAuthorizationStatusHandler.m
//  flutter_beacon
//
//  Created by Alann Maulana on 15/10/19.
//

#import "FBAuthorizationStatusHandler.h"
#import <FlutterBeaconPlugin.h>
#import <CoreBluetooth/CoreBluetooth.h>

@implementation FBAuthorizationStatusHandler

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
        self.instance.flutterEventSinkAuthorization = nil;
    }
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    // initialize central manager if it itsn't
    [self.instance initializeLocationManager];
    
    if (self.instance) {
        self.instance.flutterEventSinkAuthorization = events;
    }
    
    return nil;
}

@end
