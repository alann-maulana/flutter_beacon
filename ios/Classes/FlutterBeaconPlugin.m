#import "FlutterBeaconPlugin.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "FBUtils.h"
#import "FBRangingStreamHandler.h"
#import "FBMonitoringStreamHandler.h"

@interface FlutterBeaconPlugin() <CLLocationManagerDelegate, CBCentralManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (strong, nonatomic) NSMutableArray *regionRanging;
@property (strong, nonatomic) NSMutableArray *regionMonitoring;

@property (strong, nonatomic) FBRangingStreamHandler* rangingHandler;
@property (strong, nonatomic) FBMonitoringStreamHandler* monitoringHandler;
@property (strong, nonatomic) FBMonitoringStreamHandler* bluetoothHandler;

@property FlutterResult flutterResult;

@end

@implementation FlutterBeaconPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"flutter_beacon"
                                                                binaryMessenger:[registrar messenger]];
    FlutterBeaconPlugin* instance = [[FlutterBeaconPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    instance.rangingHandler = [[FBRangingStreamHandler alloc] initWithFlutterBeaconPlugin:instance];
    FlutterEventChannel* streamChannelRanging =
    [FlutterEventChannel eventChannelWithName:@"flutter_beacon_event"
                              binaryMessenger:[registrar messenger]];
    [streamChannelRanging setStreamHandler:instance.rangingHandler];
    
    instance.monitoringHandler = [[FBMonitoringStreamHandler alloc] initWithFlutterBeaconPlugin:instance];
    FlutterEventChannel* streamChannelMonitoring =
    [FlutterEventChannel eventChannelWithName:@"flutter_beacon_event_monitoring"
                              binaryMessenger:[registrar messenger]];
    [streamChannelMonitoring setStreamHandler:instance.monitoringHandler];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        [self initializeWithResult:result];
        return;
    }
    
    if ([@"close" isEqualToString:call.method]) {
        [self stopRangingBeacon];
        [self stopMonitoringBeacon];
        result(@(YES));
        return;
    }
    
    if ([@"state" isEqualToString:call.method]) {
        if (!self.bluetoothManager) {
            // initialize central manager if it itsn't
            self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        }
        
        switch(self.bluetoothManager.state) {
            case CBManagerStateUnknown:
                result(@"STATE_UNKNOWN");
                break;
            case CBManagerStateResetting:
                result(@"STATE_RESETTING");
                break;
            case CBManagerStateUnsupported:
                result(@"STATE_UNSUPPORTED");
                break;
            case CBManagerStateUnauthorized:
                result(@"STATE_UNAUTHORIZED");
                break;
            case CBManagerStatePoweredOff:
                result(@"STATE_OFF");
                break;
            case CBManagerStatePoweredOn:
                result(@"STATE_ON");
                break;
        }
        return;
    }
    
    result(FlutterMethodNotImplemented);
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
    self.flutterEventSinkRanging = nil;
}

///------------------------------------------------------------
#pragma mark - Flutter Beacon Monitoring
///------------------------------------------------------------

- (void) startMonitoringBeaconWithCall:(id)arguments {
    if (self.regionMonitoring) {
        [self.regionMonitoring removeAllObjects];
    } else {
        self.regionMonitoring = [NSMutableArray array];
    }
    
    NSArray *array = arguments;
    for (NSDictionary *dict in array) {
        CLBeaconRegion *region = [FBUtils regionFromDictionary:dict];
        
        if (region) {
            [self.regionMonitoring addObject:region];
        }
    }
    
    for (CLBeaconRegion *r in self.regionMonitoring) {
        NSLog(@"START: %@", r);
        [self.locationManager startMonitoringForRegion:r];
    }
}

- (void) stopMonitoringBeacon {
    for (CLBeaconRegion *region in self.regionMonitoring) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    self.flutterEventSinkMonitoring = nil;
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
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_UNKNOWN");
            }
            break;
        case CBManagerStateResetting:
            message = @"CBManagerStateResetting";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_RESETTING");
            }
            break;
        case CBManagerStateUnsupported:
            message = @"CBManagerStateUnsupported";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_UNSUPPORTED");
            }
            break;
        case CBManagerStateUnauthorized:
            message = @"CBManagerStateUnauthorized";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_UNAUTHORIZED");
            }
            break;
        case CBManagerStatePoweredOff:
            message = @"CBManagerStatePoweredOff";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_OFF");
            }
            break;
        case CBManagerStatePoweredOn:
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_ON");
            }
            if ([CLLocationManager locationServicesEnabled]) {
                if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                    //[self.locationManager requestWhenInUseAuthorization];
                    [self.locationManager requestAlwaysAuthorization];
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
            // manage scanning
            break;
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
    if (self.flutterEventSinkRanging) {
        NSDictionary *dictRegion = [FBUtils dictionaryFromCLBeaconRegion:region];
        
        NSMutableArray *array = [NSMutableArray array];
        for (CLBeacon *beacon in beacons) {
            NSDictionary *dictBeacon = [FBUtils dictionaryFromCLBeacon:beacon];
            [array addObject:dictBeacon];
        }
        
        self.flutterEventSinkRanging(@{
                                @"region": dictRegion,
                                @"beacons": array
                                });
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (self.flutterEventSinkMonitoring) {
        CLBeaconRegion *reg;
        for (CLBeaconRegion *r in self.regionMonitoring) {
            if ([region.identifier isEqualToString:r.identifier]) {
                reg = r;
                break;
            }
        }
        
        if (reg) {
            NSDictionary *dictRegion = [FBUtils dictionaryFromCLBeaconRegion:reg];
            self.flutterEventSinkMonitoring(@{
                                              @"event": @"didEnterRegion",
                                              @"region": dictRegion
                                              });
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (self.flutterEventSinkMonitoring) {
        CLBeaconRegion *reg;
        for (CLBeaconRegion *r in self.regionMonitoring) {
            if ([region.identifier isEqualToString:r.identifier]) {
                reg = r;
                break;
            }
        }
        
        if (reg) {
            NSDictionary *dictRegion = [FBUtils dictionaryFromCLBeaconRegion:reg];
            self.flutterEventSinkMonitoring(@{
                                              @"event": @"didExitRegion",
                                              @"region": dictRegion
                                              });
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (self.flutterEventSinkMonitoring) {
        CLBeaconRegion *reg;
        for (CLBeaconRegion *r in self.regionMonitoring) {
            if ([region.identifier isEqualToString:r.identifier]) {
                reg = r;
                break;
            }
        }
        
        if (reg) {
            NSDictionary *dictRegion = [FBUtils dictionaryFromCLBeaconRegion:reg];
            NSString *stt;
            switch (state) {
                case CLRegionStateInside:
                    stt = @"INSIDE";
                    break;
                case CLRegionStateOutside:
                    stt = @"OUTSIDE";
                    break;
                default:
                    stt = @"UNKNOWN";
                    break;
            }
            self.flutterEventSinkMonitoring(@{
                                              @"event": @"didDetermineStateForRegion",
                                              @"region": dictRegion,
                                              @"state": stt
                                              });
        }
    }
}

@end
