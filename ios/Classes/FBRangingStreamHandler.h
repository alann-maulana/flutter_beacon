//
//  FBRangingStreamHandler.h
//  flutter_beacon
//
//  Created by Alann Maulana on 23/01/19.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@class FlutterBeaconPlugin;
@interface FBRangingStreamHandler : NSObject<FlutterStreamHandler>

@property (strong, nonatomic) FlutterBeaconPlugin* instance;

- (instancetype) initWithFlutterBeaconPlugin:(FlutterBeaconPlugin*) instance;

@end

NS_ASSUME_NONNULL_END
