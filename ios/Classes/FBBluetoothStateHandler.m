//
//  FBBluetoothStateHandler.m
//  flutter_beacon
//
//  Created by Alann Maulana on 24/08/19.
//

#import "FBBluetoothStateHandler.h"
#import <FlutterBeaconPlugin.h>
#import <CoreBluetooth/CoreBluetooth.h>

@implementation FBBluetoothStateHandler

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
        self.instance.flutterEventSinkBluetooth = nil;
    }
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    // initialize central manager if it itsn't
    [self.instance initializeCentralManager];
    
    if (self.instance) {
        self.instance.flutterEventSinkBluetooth = events;
    }
    
    return nil;
}

@end
