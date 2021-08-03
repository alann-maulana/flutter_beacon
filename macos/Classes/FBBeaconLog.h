#import <Foundation/Foundation.h>

@class RACSignal;
@class FBBeacon;
@interface FBBeaconLog : NSObject

- (void)addBeacon:(FBBeacon *)beacon;
- (id)initWithBeaconSignal:(RACSignal *)beaconSignal maximumLogSize:(NSUInteger) max;
- (id)initWithBeaconSignal:(RACSignal *)beaconSignal;

@end
