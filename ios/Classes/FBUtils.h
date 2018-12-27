//
//  FBUtils.h
//  flutter_beacon
//
//  Created by Alann Maulana on 26/12/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLBeacon;
@class CLBeaconRegion;
@interface FBUtils : NSObject

+ (NSDictionary * _Nonnull) dictionaryFromCLBeacon:(CLBeacon*) beacon;
+ (NSDictionary * _Nonnull) dictionaryFromCLBeaconRegion:(CLBeaconRegion*) region;

+ (CLBeaconRegion * _Nullable) regionFromDictionary:(NSDictionary*) dict;

@end

NS_ASSUME_NONNULL_END
