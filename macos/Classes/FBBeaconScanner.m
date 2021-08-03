#import "FBBeaconScanner.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FBBeacon.h"
#import "libextobjc/EXTScope.h"
#import "BlocksKit.h"
#import "FBBluetoothState.h"

@interface FBBeaconScanner () <CLLocationManagerDelegate,CBCentralManagerDelegate>
@property (strong,nonatomic) CBCentralManager *centralManager;
@property (nonatomic, strong) dispatch_queue_t managerQueue;
@property (nonatomic, strong) RACSubject *beaconSignal;
@property (nonatomic, strong) RACSubject *bluetoothStateSignal;
@property (nonatomic, assign) NSString *const bluetoothState;
@property (nonatomic, strong) RACSignal*housekeepingIntervalSignal;
@property (nonatomic, assign) BOOL scanning;
@end
@implementation FBBeaconScanner
#pragma mark - beacon
-(id)init {
    self  = [super init];
    if (self) {
        
        self.managerQueue = dispatch_queue_create("com.flutter.beacon.centralManagerQueue", NULL);
        
        
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:self.managerQueue];
        
        self.beaconSignal = [RACReplaySubject replaySubjectWithCapacity:1];
        self.bluetoothStateSignal = [RACReplaySubject replaySubjectWithCapacity:1];
        
    }
    return self;
}

-(void)stopScanning {
    [self.centralManager stopScan];
    self.scanning = NO;
}

-(void)startScanning {
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil
                                                    options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
        self.scanning = YES;
    }
    
}


-(NSNumber *)bluetoothLMPVersion {
    static NSNumber *bluetoothLMPVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPipe *outputPipe = [[NSPipe alloc] init];
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/bash";
        if (floor(kCFCoreFoundationVersionNumber) > kCFCoreFoundationVersionNumber10_10) {
            task.arguments = @[ @"-c", @"system_profiler -detailLevel full SPBluetoothDataType | grep 'LMP Version:' | awk '{print $4}' | tr -d '(' | tr -d ')'"];
        } else {
            task.arguments = @[ @"-c", @"system_profiler -detailLevel full SPBluetoothDataType | grep 'LMP Version:' | awk '{print $3}'"];
        }
        task.standardOutput = outputPipe;
        [task launch];
        [task waitUntilExit];
        NSData *output = [[outputPipe fileHandleForReading] availableData];
        NSString *outputString = [[[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n"withString:@""];
        NSScanner *outputScanner = [NSScanner scannerWithString:outputString];
        unsigned int outputInt = 0;
        [outputScanner scanHexInt:&outputInt];
        bluetoothLMPVersion = [NSNumber numberWithUnsignedInteger:outputInt];
    });
    return bluetoothLMPVersion;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *state = nil;
    switch (central.state) {
        case CBCentralManagerStateResetting:
            state = FBBluetoothStateResetting;
            break;
        case CBCentralManagerStateUnsupported:
            state = FBBluetoothStateUnsupported;
            break;
        case CBCentralManagerStateUnauthorized:
            state = FBBluetoothStateUnauthorized;
            break;
        case CBCentralManagerStatePoweredOff:
            //LMP version of 0x4 reports itself off, even though its' actually unsupported;
            if ([[self bluetoothLMPVersion] integerValue] < 6) {
                state = FBBluetoothStateUnsupported;
            } else {
                state = FBBluetoothStatePoweredOff;
            }
            break;
        case CBCentralManagerStatePoweredOn:
            state = FBBluetoothStatePoweredOn;
            break;
        default:
            state = FBBluetoothStateUnknown;
            break;
            
    }
    if (state != FBBluetoothStatePoweredOn) {
        if (self.scanning) {
            [self stopScanning];
        }
    }
    self.bluetoothState = state;
    [(RACSubject *)self.bluetoothStateSignal sendNext:state];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    FBBeacon *beacon = [FBBeacon beaconWithAdvertiseDictionary:advertisementData];
    beacon.rssi = RSSI;
    if (beacon) {
        [(RACSubject *)self.beaconSignal sendNext:beacon];
    }
}

+(FBBeaconScanner *)sharedBeaconScanner {
    static FBBeaconScanner *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[FBBeaconScanner alloc] init];
    });
    return sharedManager;
}
@end
