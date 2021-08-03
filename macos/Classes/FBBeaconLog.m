#import "FBBeaconLog.h"
#import "FBBeacon.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import <BlocksKit/BlocksKit.h>

static const NSUInteger HGBeaconHistoryDefaultMaximumSize = 300;
@interface FBBeaconLog()
@property(nonatomic, strong) NSMutableDictionary *beaconSubjectMap;
@property(nonatomic, assign) NSUInteger maximumHistorySize;
//@property(nonatomic, strong) RACSignal *beaconSignal;
@end

@implementation FBBeaconLog

-(id)initWithBeaconSignal:(RACSignal *)beaconSignal {
    return [self initWithBeaconSignal:beaconSignal maximumLogSize:HGBeaconHistoryDefaultMaximumSize];
}

-(id)initWithBeaconSignal:(RACSignal *)beaconSignal maximumLogSize:(NSUInteger)maximumHistorySize{
    self = [super init];
    if (self) {
        _maximumHistorySize = maximumHistorySize;
        _beaconSubjectMap = [[NSMutableDictionary alloc] init];
        @weakify(self)
        [beaconSignal subscribeNext:^(FBBeacon *beacon) {
            @strongify(self)
            [self addBeacon:beacon];
        }];
    }
    return self;
}

- (RACSubject *)subjectForBeacon:(FBBeacon *)beacon {
    NSString *key = [NSString stringWithFormat:@"%@-%@-%@", beacon.proximityUUID, beacon.major, beacon.minor];
    RACReplaySubject *beaconSubject = self.beaconSubjectMap[key];
    if (! beaconSubject ) {
        beaconSubject = [RACReplaySubject replaySubjectWithCapacity:self.maximumHistorySize];
        self.beaconSubjectMap[key] = beaconSubject;
    }
    return beaconSubject;
}

- (RACSignal *)signalForBeacon:(FBBeacon *)beacon {
    return (RACSignal *)[self subjectForBeacon:beacon];
}

-(void)addBeacon:(FBBeacon *)beacon {
    [[self subjectForBeacon:beacon] sendNext:beacon];
}





@end
