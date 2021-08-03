#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef uint16_t CLBeaconMajorValue;
typedef uint16_t CLBeaconMinorValue;

@class FBBeacon;
@interface FBRegion : NSObject

@property (readonly, nonatomic, copy) NSString *identifier;
@property (readonly, nonatomic, copy) NSUUID *uuid;
@property (readonly, nonatomic, copy, nullable) NSNumber *major;
@property (readonly, nonatomic, copy, nullable) NSNumber *minor;

- (instancetype)initWithUUID:(NSUUID *)uuid identifier:(NSString *)identifier;
- (instancetype)initWithUUID:(NSUUID *)uuid major:(CLBeaconMajorValue)major identifier:(NSString *)identifier;
- (instancetype)initWithUUID:(NSUUID *)uuid major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier;
- (instancetype _Nullable) initWithDictionary:(NSDictionary* _Nullable) dict;
- (BOOL) isBeaconInRegion:(FBBeacon* _Nonnull) beacon;

- (NSDictionary * _Nonnull) dictionaryFromRegion;

@end

NS_ASSUME_NONNULL_END
