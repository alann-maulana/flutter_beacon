#import "FlutterBeaconPlugin.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "FBUtils.h"
#import "FBBluetoothStateHandler.h"
#import "FBRangingStreamHandler.h"
#import "FBMonitoringStreamHandler.h"
#import "FBAuthorizationStatusHandler.h"

@interface FlutterBeaconPlugin() <CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate>

@property (assign, nonatomic) CLAuthorizationStatus defaultLocationAuthorizationType;
@property (assign) BOOL shouldStartAdvertise;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) NSMutableArray *regionRanging;
@property (strong, nonatomic) NSMutableArray *regionMonitoring;
@property (strong, nonatomic) NSDictionary *beaconPeripheralData;

@property (strong, nonatomic) FBRangingStreamHandler* rangingHandler;
@property (strong, nonatomic) FBMonitoringStreamHandler* monitoringHandler;
@property (strong, nonatomic) FBBluetoothStateHandler* bluetoothHandler;
@property (strong, nonatomic) FBAuthorizationStatusHandler* authorizationHandler;

@property FlutterResult flutterResult;
@property FlutterResult flutterBluetoothResult;
@property FlutterResult flutterBroadcastResult;

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
    
    instance.bluetoothHandler = [[FBBluetoothStateHandler alloc] initWithFlutterBeaconPlugin:instance];
    FlutterEventChannel* streamChannelBluetooth =
    [FlutterEventChannel eventChannelWithName:@"flutter_bluetooth_state_changed"
                              binaryMessenger:[registrar messenger]];
    [streamChannelBluetooth setStreamHandler:instance.bluetoothHandler];
    
    instance.authorizationHandler = [[FBAuthorizationStatusHandler alloc] initWithFlutterBeaconPlugin:instance];
    FlutterEventChannel* streamChannelAuthorization =
    [FlutterEventChannel eventChannelWithName:@"flutter_authorization_status_changed"
                              binaryMessenger:[registrar messenger]];
    [streamChannelAuthorization setStreamHandler:instance.authorizationHandler];
}

- (id)init {
    self = [super init];
    if (self) {
        // Earlier versions of flutter_beacon only supported "always" permission,
        // so set this as the default to stay backwards compatible.
        self.defaultLocationAuthorizationType = kCLAuthorizationStatusAuthorizedAlways;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        [self initializeLocationManager];
        [self initializeCentralManager];
        result(@(YES));
        return;
    }
    
    if ([@"initializeAndCheck" isEqualToString:call.method]) {
        [self initializeWithResult:result];
        return;
    }
    
    if ([@"setLocationAuthorizationTypeDefault" isEqualToString:call.method]) {
        if (call.arguments != nil && [call.arguments isKindOfClass:[NSString class]]) {
            NSString *argumentAsString = (NSString*)call.arguments;
            if ([@"ALWAYS" isEqualToString:argumentAsString]) {
                self.defaultLocationAuthorizationType = kCLAuthorizationStatusAuthorizedAlways;
                result(@(YES));
                return;
            }
            if ([@"WHEN_IN_USE" isEqualToString:argumentAsString]) {
                self.defaultLocationAuthorizationType = kCLAuthorizationStatusAuthorizedWhenInUse;
                result(@(YES));
                return;
            }
        }
        result(@(NO));
        return;
    }

    if ([@"authorizationStatus" isEqualToString:call.method]) {
        [self initializeLocationManager];
        
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusNotDetermined:
                result(@"NOT_DETERMINED");
                break;
            case kCLAuthorizationStatusRestricted:
                result(@"RESTRICTED");
                break;
            case kCLAuthorizationStatusDenied:
                result(@"DENIED");
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
                result(@"ALWAYS");
                break;
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                result(@"WHEN_IN_USE");
                break;
        }
        return;
    }
    
    if ([@"checkLocationServicesIfEnabled" isEqualToString:call.method]) {
        result(@([CLLocationManager locationServicesEnabled]));
        return;
    }
    
    if ([@"bluetoothState" isEqualToString:call.method]) {
        self.flutterBluetoothResult = result;
        [self initializeCentralManager];
        
        // Delay 2 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.flutterBluetoothResult) {
                switch(self.bluetoothManager.state) {
                    case CBManagerStateUnknown:
                        self.flutterBluetoothResult(@"STATE_UNKNOWN");
                        break;
                    case CBManagerStateResetting:
                        self.flutterBluetoothResult(@"STATE_RESETTING");
                        break;
                    case CBManagerStateUnsupported:
                        self.flutterBluetoothResult(@"STATE_UNSUPPORTED");
                        break;
                    case CBManagerStateUnauthorized:
                        self.flutterBluetoothResult(@"STATE_UNAUTHORIZED");
                        break;
                    case CBManagerStatePoweredOff:
                        self.flutterBluetoothResult(@"STATE_OFF");
                        break;
                    case CBManagerStatePoweredOn:
                        self.flutterBluetoothResult(@"STATE_ON");
                        break;
                }
                self.flutterBluetoothResult = nil;
            }
        });
        return;
    }
    
    if ([@"requestAuthorization" isEqualToString:call.method]) {
        if (self.locationManager) {
            self.flutterResult = result;
            [self requestDefaultLocationManagerAuthorization];
        } else {
            result(@(YES));
        }
        return;
    }
    
    if ([@"openBluetoothSettings" isEqualToString:call.method]) {
        // do nothing
        
        // Beware, this is considered as a private API and Apple will rejecte your application
        // Uncomment these codes below if your want to publish this app privately
        /*
        NSString *settingsUrl= @"App-Prefs:root=Bluetooth";
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:settingsUrl] options:@{} completionHandler:^(BOOL success) {
                    NSLog(@"Bluetooth settings opened");
                }];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:settingsUrl]];
            }
        }
         */
        
        result(@(YES));
        return;
    }
    
    if ([@"openLocationSettings" isEqualToString:call.method]) {
        // // do nothing
        
        // Beware, this is considered as a private API and Apple will reject your application
        // Uncomment these codes below if your want to publish this app privately
        /*
        NSString *settingsUrl= @"App-Prefs:root=Privacy&path=LOCATION";
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:settingsUrl] options:@{} completionHandler:^(BOOL success) {
                    NSLog(@"Location settings opened");
                }];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:settingsUrl]];
            }
        }
         */
        
        result(@(YES));
        return;
    }

    if ([@"setScanPeriod" isEqualToString:call.method]) {
        // do nothing

        result(@(YES));
        return;
    }

    if ([@"setBetweenScanPeriod" isEqualToString:call.method]) {
        // do nothing

        result(@(YES));
        return;
    }
    
    if ([@"openApplicationSettings" isEqualToString:call.method]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        result(@(YES));
        return;
    }
    
    if ([@"close" isEqualToString:call.method]) {
        [self stopRangingBeacon];
        [self stopMonitoringBeacon];
        result(@(YES));
        return;
    }
    
    if ([@"startBroadcast" isEqualToString:call.method]) {
        self.flutterBroadcastResult = result;
        [self startBroadcast:call.arguments];
        return;
    }
    
    if ([@"stopBroadcast" isEqualToString:call.method]) {
        if (self.peripheralManager) {
            [self.peripheralManager stopAdvertising];
        }
        result(nil);
        return;
    }
    
    if ([@"isBroadcasting" isEqualToString:call.method]) {
        if (self.peripheralManager) {
            result(@([self.peripheralManager isAdvertising]));
        } else {
            result(@(NO));
        }
        return;
    }
    
    if ([@"isBroadcastSupported" isEqualToString:call.method]) {
        result(@(YES));
        return;
    }
    
    result(FlutterMethodNotImplemented);
}

- (void) initializeCentralManager {
    if (!self.bluetoothManager) {
        // initialize central manager if it itsn't
        self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
}

- (void) initializeLocationManager {
    if (!self.locationManager) {
        // initialize location manager if it itsn't
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

- (void) startBroadcast:(id)arguments {
    NSDictionary *dict = arguments;
    NSNumber *measuredPower = nil;
    if (dict[@"txPower"] != [NSNull null]) {
        measuredPower = dict[@"txPower"];
    }
    CLBeaconRegion *region = [FBUtils regionFromDictionary:dict];
    
    self.shouldStartAdvertise = YES;
    self.beaconPeripheralData = [region peripheralDataWithMeasuredPower:measuredPower];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
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
    
    [self initializeLocationManager];
    [self initializeCentralManager];
}

///------------------------------------------------------------
#pragma mark - Bluetooth Manager
///------------------------------------------------------------

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *message = nil;
    switch(central.state) {
        case CBManagerStateUnknown:
            if (self.flutterBluetoothResult) {
                self.flutterBluetoothResult(@"STATE_UNKNOWN");
                self.flutterBluetoothResult = nil;
                return;
            }
            message = @"CBManagerStateUnknown";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_UNKNOWN");
            }
            break;
        case CBManagerStateResetting:
            if (self.flutterBluetoothResult) {
                self.flutterBluetoothResult(@"STATE_RESETTING");
                self.flutterBluetoothResult = nil;
                return;
            }
            message = @"CBManagerStateResetting";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_RESETTING");
            }
            break;
        case CBManagerStateUnsupported:
            if (self.flutterBluetoothResult) {
                self.flutterBluetoothResult(@"STATE_UNSUPPORTED");
                self.flutterBluetoothResult = nil;
                return;
            }
            message = @"CBManagerStateUnsupported";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_UNSUPPORTED");
            }
            break;
        case CBManagerStateUnauthorized:
            if (self.flutterBluetoothResult) {
                self.flutterBluetoothResult(@"STATE_UNAUTHORIZED");
                self.flutterBluetoothResult = nil;
                return;
            }
            message = @"CBManagerStateUnauthorized";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_UNAUTHORIZED");
            }
            break;
        case CBManagerStatePoweredOff:
            if (self.flutterBluetoothResult) {
                self.flutterBluetoothResult(@"STATE_OFF");
                self.flutterBluetoothResult = nil;
                return;
            }
            message = @"CBManagerStatePoweredOff";
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_OFF");
            }
            break;
        case CBManagerStatePoweredOn:
            if (self.flutterBluetoothResult) {
                self.flutterBluetoothResult(@"STATE_ON");
                self.flutterBluetoothResult = nil;
                return;
            }
            if (self.flutterEventSinkBluetooth) {
                self.flutterEventSinkBluetooth(@"STATE_ON");
            }
            if ([CLLocationManager locationServicesEnabled]) {
                if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                    [self requestDefaultLocationManagerAuthorization];
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

- (void)requestDefaultLocationManagerAuthorization {
    switch (self.defaultLocationAuthorizationType) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self.locationManager requestWhenInUseAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        default:
            [self.locationManager requestAlwaysAuthorization];
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *message = nil;
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            if (self.flutterEventSinkAuthorization) {
                self.flutterEventSinkAuthorization(@"ALWAYS");
            }
            // manage scanning
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (self.flutterEventSinkAuthorization) {
                self.flutterEventSinkAuthorization(@"WHEN_IN_USE");
            }
            // manage scanning
            break;
        case kCLAuthorizationStatusDenied:
            if (self.flutterEventSinkAuthorization) {
                self.flutterEventSinkAuthorization(@"DENIED");
            }
            message = @"CLAuthorizationStatusDenied";
            break;
        case kCLAuthorizationStatusRestricted:
            if (self.flutterEventSinkAuthorization) {
                self.flutterEventSinkAuthorization(@"RESTRICTED");
            }
            message = @"CLAuthorizationStatusRestricted";
            break;
        case kCLAuthorizationStatusNotDetermined:
            if (self.flutterEventSinkAuthorization) {
                self.flutterEventSinkAuthorization(@"NOT_DETERMINED");
            }
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

///------------------------------------------------------------
#pragma mark - Peripheral Manager
///------------------------------------------------------------

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            if (self.shouldStartAdvertise) {
                [peripheral startAdvertising:self.beaconPeripheralData];
                self.shouldStartAdvertise = NO;
            }
            break;
        default:
            break;
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error {
    if (!self.flutterBroadcastResult) {
        return;
    }
    
    if (error) {
        self.flutterBroadcastResult([FlutterError errorWithCode:@"Broadcast" message:error.localizedDescription details:error]);
    } else {
        self.flutterBroadcastResult(@(peripheral.isAdvertising));
    }
    self.flutterBroadcastResult = nil;
}

@end
