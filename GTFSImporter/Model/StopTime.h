//
//  StopTime.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface StopTime : NSObject

@property (nonatomic, strong) NSString *arrivalTime;
@property (nonatomic, strong) NSString *departureTime;
@property (nonatomic, strong) NSNumber *stopSequence;
@property (nonatomic, strong) NSString *tripId;
@property (nonatomic, strong) NSString *stopId;
@property (nonatomic, strong) NSNumber *isTimepoint;

- (void)addStopTime:(StopTime *)stopTime;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;
- (NSArray *)getStopsForTripId:(NSString *)tripId;
- (void)interpolateStopTimes;
- (NSArray *)getTimeInterpolatedStopTimesByTripId:(NSString *)tripId;
- (NSArray *)getStopTimesByTripId:(NSString *)tripId;
- (void)updateStopTimes:(NSArray *)interpolatedStopTimes;


@end