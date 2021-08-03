#import "ReactiveObjC/ReactiveObjC.h"
@interface FBBeacon : NSObject

@property (strong,nonatomic) NSUUID *proximityUUID;
@property (strong,nonatomic) NSNumber *major;
@property (strong,nonatomic) NSNumber *minor;
@property (strong,nonatomic) NSNumber *measuredPower;
@property (strong,nonatomic) NSNumber *RSSI;
@property (strong,nonatomic) NSDate *lastUpdated;

@property (nonatomic, readonly) NSString *keyValue;

- (id)initWithProximityUUID:(NSUUID *)proximityUUID
                      major:(NSNumber *)major
                      minor:(NSNumber *)minor
              measuredPower:(NSNumber *)power;


+ (FBBeacon *)beaconWithAdvertiseDictionary:(NSDictionary *)dictionary;
+ (FBBeacon *)beaconWithManufacturerAdvertiseData:(NSData *)data;
- (BOOL)isEqualToBeacon:(FBBeacon *)otherBeacon;

- (NSDictionary *)advertiseDictionary;

@end
