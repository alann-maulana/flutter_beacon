//
//  FBRangingStreamHandler.m
//  flutter_beacon
//
//  Created by Alann Maulana on 23/01/19.
//

#import "FBRangingStreamHandler.h"
#import <FlutterBeaconPlugin.h>

@implementation FBRangingStreamHandler

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
        [self.instance stopRangingBeacon];
    }
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    if (self.instance) {
        self.instance.flutterEventSinkRanging = events;
        [self.instance startRangingBeaconWithCall:arguments];
    }
    return nil;
}

@end
