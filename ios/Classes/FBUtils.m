//
//  FBUtils.m
//  flutter_beacon
//
//  Created by Alann Maulana on 26/12/18.
//

#import "FBUtils.h"
#import <CoreLocation/CoreLocation.h>

@implementation FBUtils

+ (NSDictionary * _Nonnull) dictionaryFromCLBeacon:(CLBeacon*) beacon {
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityUnknown:
            proximity = @"unknown";
            break;
        case CLProximityImmediate:
            proximity = @"immediate";
            break;
        case CLProximityNear:
            proximity = @"near";
            break;
        case CLProximityFar:
            proximity = @"far";
            break;
    }
    
    NSNumber *rssi = [NSNumber numberWithInteger:beacon.rssi];
    return @{
             @"proximityUUID": [beacon.proximityUUID UUIDString],
             @"major": beacon.major,
             @"minor": beacon.minor,
             @"rssi": rssi,
             @"accuracy": [NSString stringWithFormat:@"%.2f", beacon.accuracy],
             @"proximity": proximity
             };
}

+ (NSDictionary * _Nonnull) dictionaryFromCLBeaconRegion:(CLBeaconRegion*) region {
    id major = region.major;
    if (!major) {
        major = [NSNull null];
    }
    id minor = region.minor;
    if (!minor) {
        minor = [NSNull null];
    }
    
    return @{
             @"identifier": region.identifier,
             @"proximityUUID": [region.proximityUUID UUIDString],
             @"major": major,
             @"minor": minor,
             };
}

+ (CLBeaconRegion * _Nullable) regionFromDictionary:(NSDictionary*) dict {
    NSString *identifier = dict[@"identifier"];
    NSString *proximityUUID = dict[@"proximityUUID"];
    NSNumber *major = dict[@"major"];
    NSNumber *minor = dict[@"minor"];
    
    CLBeaconRegion *region = nil;
    if (proximityUUID && major && minor) {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID] major:[major intValue] minor:[minor intValue] identifier:identifier];
    } else if (proximityUUID && major) {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID] major:[major intValue] identifier:identifier];
    } else if (proximityUUID) {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID] identifier:identifier];
    }
    
    return region;
}

@end
