#import <Foundation/Foundation.h>
#import "ReactiveObjC/ReactiveObjC.h"


@interface FBBeaconScanner : NSObject
/**
 *  Signal that send an HGBeacon to subscribers every time a beacon is detected (or redetected)
 */
@property (nonatomic, readonly) RACSignal *beaconSignal;

/**
 *  Signal that will send one of the HGBeconScannerBluetoothState prefexed consts
 *  defined above when bluetooth state changes
 */
@property (nonatomic, readonly) RACSignal *bluetoothStateSignal;
/**
 *  Value will be one of the HGBeconScannerBluetoothState prefexed consts
 *  defined above when bluetooth state changes
 */
@property (nonatomic, readonly) NSString *const bluetoothState;

@property (nonatomic, readonly) BOOL scanning;
/**
 *  Starts scanning for beacons
 */
-(void)startScanning;
/**
 *  Stops scanning for beacons
 */
-(void)stopScanning;
-(NSNumber *)bluetoothLMPVersion;

+(FBBeaconScanner *)sharedBeaconScanner;
@end
