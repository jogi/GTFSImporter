//
//  StopTime.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface StopTime : NSObject {
    FMDatabase *db;
    NSString * arrival_time;
    NSString * departure_time;
    NSNumber * stop_sequence;
    NSString * trip_id;
    NSString * stop_id;
    NSNumber * is_timepoint;
}

@property (nonatomic, retain) NSString * arrival_time;
@property (nonatomic, retain) NSString * departure_time;
@property (nonatomic, retain) NSNumber * stop_sequence;
@property (nonatomic, retain) NSString * trip_id;
@property (nonatomic, retain) NSString * stop_id;
@property (nonatomic, retain) NSNumber * is_timepoint;

- (void)addStopTime:(StopTime *)stopTime;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;
- (NSArray *) getStopsForTripId:(NSString *)tripId;
- (void) interpolateStopTimes;
- (NSArray *) getTimeInterpolatedStopTimesByTripId:(NSString *)tripId;
- (NSArray *) getStopTimesByTripId:(NSString *)tripId;
- (void) updateStopTimes:(NSArray *)interpolatedStopTimes;


@end