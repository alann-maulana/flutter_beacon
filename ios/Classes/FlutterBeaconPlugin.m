#import "FlutterBeaconPlugin.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "FBUtils.h"

@interface FlutterBeaconPlugin() <CLLocationManagerDelegate, CBCentralManagerDelegate, FlutterStreamHandler>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (strong, nonatomic) NSMutableArray *regionRanging;

@property FlutterResult flutterResult;
@property FlutterEventSink flutterEventSink;

@end

@implementation FlutterBeaconPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"flutter_beacon"
                                                                binaryMessenger:[registrar messenger]];
    FlutterBeaconPlugin* instance = [[FlutterBeaconPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel* streamChannel =
    [FlutterEventChannel eventChannelWithName:@"flutter_beacon_event"
                              binaryMessenger:[registrar messenger]];
    [streamChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        [self initializeWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

///------------------------------------------------------------
#pragma mark - Flutter Beacon Ranging
///------------------------------------------------------------

- (void) startRangingBeaconWithCall:(id)arguments {
    if (self.regionRanging) {
        [self.regionRanging removeAllObjects];
    } else {
        self.regionRanging = [NSMutableArray array];
    }
    
    NSArray *array = arguments;
    for (NSDictionary *dict in array) {
        CLBeaconRegion *region = [FBUtils regionFromDictionary:dict];
        
        if (region) {
            [self.regionRanging addObject:region];
        }
    }
    
    for (CLBeaconRegion *r in self.regionRanging) {
        NSLog(@"START: %@", r);
        [self.locationManager startRangingBeaconsInRegion:r];
    }
}

- (void) stopRangingBeacon {
    for (CLBeaconRegion *region in self.regionRanging) {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
    self.flutterEventSink = nil;
}

///------------------------------------------------------------
#pragma mark - Flutter Beacon Initialize
///------------------------------------------------------------

- (void) initializeWithResult:(FlutterResult)result {
    self.flutterResult = result;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // Initialize central manager and detect bluetooth state
    self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}

///------------------------------------------------------------
#pragma mark - Bluetooth Manager
///------------------------------------------------------------

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *message = nil;
    switch(central.state) {
        case CBManagerStateUnknown:
            message = @"CBManagerStateUnknown";
            break;
        case CBManagerStateResetting:
            message = @"CBManagerStateResetting";
            break;
        case CBManagerStateUnsupported:
            message = @"CBManagerStateUnsupported";
            break;
        case CBManagerStateUnauthorized:
            message = @"CBManagerStateUnauthorized";
            break;
        case CBManagerStatePoweredOff:
            message = @"CBManagerStatePoweredOff";
            break;
        case CBManagerStatePoweredOn:
            if ([CLLocationManager locationServicesEnabled]) {
                if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                    [self.locationManager requestWhenInUseAuthorization];
                    return;
                } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
                    message = @"CLAuthorizationStatusDenied";
                } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
                    message = @"CLAuthorizationStatusRestricted";
                } else {
                    // manage scanning
                }
            } else {
                message = @"LocationServicesDisabled";
            }
    }
    
    if (self.flutterResult) {
        if (message) {
            self.flutterResult([FlutterError errorWithCode:@"Beacon" message:message details:nil]);
        } else {
            self.flutterResult(nil);
        }
    }
}

///------------------------------------------------------------
#pragma mark - Location Manager
///------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *message = nil;
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            // manage scanning
            break;
        case kCLAuthorizationStatusDenied:
            message = @"CLAuthorizationStatusDenied";
            break;
        case kCLAuthorizationStatusRestricted:
            message = @"CLAuthorizationStatusRestricted";
            break;
        case kCLAuthorizationStatusNotDetermined:
            message = @"CLAuthorizationStatusNotDetermined";
            break;
    }
    
    if (self.flutterResult) {
        if (message) {
            self.flutterResult([FlutterError errorWithCode:@"Beacon" message:message details:nil]);
        } else {
            self.flutterResult(nil);
        }
    }
}

-(void)locationManager:(CLLocationManager*)manager didRangeBeacons:(NSArray*)beacons inRegion:(CLBeaconRegion*)region{
    if (self.flutterEventSink) {
        NSDictionary *dictRegion = [FBUtils dictionaryFromCLBeaconRegion:region];
        
        NSMutableArray *array = [NSMutableArray array];
        for (CLBeacon *beacon in beacons) {
            NSDictionary *dictBeacon = [FBUtils dictionaryFromCLBeacon:beacon];
            [array addObject:dictBeacon];
        }
        
        self.flutterEventSink(@{
                                @"region": dictRegion,
                                @"beacons": array
                                });
    }
}

///------------------------------------------------------------
#pragma mark - Flutter Stream Handler
///------------------------------------------------------------

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    [self stopRangingBeacon];
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    self.flutterEventSink = events;
    [self startRangingBeaconWithCall:arguments];
    return nil;
}

@end
