#import "ReactiveObjC/ReactiveObjC.h"

@class FBRegion;
@interface FBBeacon : NSObject

@property (strong,nonatomic) NSUUID * _Nonnull proximityUUID;
@property (strong,nonatomic) NSNumber * _Nonnull major;
@property (strong,nonatomic) NSNumber * _Nonnull minor;
@property (strong,nonatomic) NSNumber * _Nonnull measuredPower;
@property (strong,nonatomic) NSNumber * _Nonnull rssi;
@property (strong,nonatomic) NSDate * _Nonnull lastUpdated;
@property (strong,nonatomic) FBRegion * _Nullable region;

- (id _Nonnull)initWithProximityUUID:(NSUUID * _Nonnull)proximityUUID
                               major:(NSNumber * _Nonnull)major
                               minor:(NSNumber * _Nonnull)minor
                       measuredPower:(NSNumber * _Nonnull)power;


+ (FBBeacon * _Nonnull)beaconWithAdvertiseDictionary:(NSDictionary * _Nonnull)dictionary;
+ (FBBeacon * _Nonnull)beaconWithManufacturerAdvertiseData:(NSData * _Nonnull)data;
- (BOOL)isEqualToBeacon:(FBBeacon * _Nonnull)otherBeacon;

- (NSDictionary * _Nonnull) advertiseDictionary;
- (NSDictionary<NSString*, NSObject*> * _Nonnull) dictionaryBeacon;

@end
