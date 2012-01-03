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
    NSNumber * trip_id;
    NSNumber * stop_id;
    NSNumber * is_timepoint;
}

@property (nonatomic, retain) NSString * arrival_time;
@property (nonatomic, retain) NSString * departure_time;
@property (nonatomic, retain) NSNumber * stop_sequence;
@property (nonatomic, retain) NSNumber * trip_id;
@property (nonatomic, retain) NSNumber * stop_id;
@property (nonatomic, retain) NSNumber * is_timepoint;

- (void)addStopTime:(StopTime *)stopTime;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;
- (NSArray *) getStopsForTripId:(NSNumber *)tripId;
- (void) interpolateStopTimes;
- (NSArray *) getTimeInterpolatedStopTimesByTripId:(NSNumber *)tripId;
- (NSArray *) getStopTimesByTripId:(NSNumber *)tripId;
- (void) updateStopTimes:(NSArray *)interpolatedStopTimes;


@end