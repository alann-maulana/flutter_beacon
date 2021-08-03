#import "FBRegion.h"
#import "FBBeacon.h"

@implementation FBRegion

- (instancetype)initWithUUID:(NSUUID *)uuid
                  identifier:(NSString *)identifier {
    if (self = [super init]) {
        _uuid = uuid;
        _identifier = identifier;
    }
    
    return self;
}

- (instancetype)initWithUUID:(NSUUID *)uuid
                       major:(CLBeaconMajorValue)major
                  identifier:(NSString *)identifier {
    if (self = [super init]) {
        _uuid = uuid;
        _major = [NSNumber numberWithInt:major];
        _identifier = identifier;
    }
    
    return self;
}

- (instancetype)initWithUUID:(NSUUID *)uuid
                       major:(CLBeaconMajorValue)major
                       minor:(CLBeaconMinorValue)minor
                  identifier:(NSString *)identifier {
    if (self = [super init]) {
        _uuid = uuid;
        _major = [NSNumber numberWithInt:major];
        _minor = [NSNumber numberWithInt:minor];
        _identifier = identifier;
    }
    
    return self;
}

- (instancetype _Nullable) initWithDictionary:(NSDictionary* _Nullable) dict {
    NSString *identifier = dict[@"identifier"];
    NSString *proximityUUID = dict[@"proximityUUID"];
    NSNumber *major = dict[@"major"];
    NSNumber *minor = dict[@"minor"];
    
    FBRegion *region = nil;
    if (identifier) {
        if (proximityUUID && major && minor) {
            region = [[FBRegion alloc] initWithUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID]
                                              major:[major intValue]
                                              minor:[minor intValue]
                                         identifier:identifier];
        } else if (proximityUUID && major) {
            region = [[FBRegion alloc] initWithUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID]
                                              major:[major intValue]
                                         identifier:identifier];
        } else if (proximityUUID) {
            region = [[FBRegion alloc] initWithUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID]
                                         identifier:identifier];
        }
    }
    
    return region;
}

- (BOOL) isBeaconInRegion:(FBBeacon* _Nonnull) beacon {
    if (self.uuid && self.major && self.minor) {
        return [self.uuid isEqualTo:beacon.proximityUUID]
        && [self.major isEqualTo:beacon.major]
        && [self.minor isEqualTo:beacon.minor];
    }
    
    if (self.uuid && self.major) {
        return [self.uuid isEqualTo:beacon.proximityUUID]
        && [self.major isEqualTo:beacon.major];
    }
    
    if (self.uuid) {
        return [self.uuid isEqualTo:beacon.proximityUUID];
    }
    
    return NO;
}

- (NSDictionary * _Nonnull) dictionaryFromRegion {
    id major = self.major;
    if (!major) {
        major = [NSNull null];
    }
    id minor = self.minor;
    if (!minor) {
        minor = [NSNull null];
    }
    
    return @{
        @"identifier": self.identifier,
        @"proximityUUID": [self.uuid UUIDString],
        @"major": major,
        @"minor": minor,
    };
}

@end
