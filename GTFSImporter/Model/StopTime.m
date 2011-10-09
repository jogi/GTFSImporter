//
//  StopTime.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "StopTime.h"
#import "Trip.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Util.h"


@implementation StopTime
@synthesize arrival_time, departure_time, stop_sequence, trip_id, stop_id, is_timepoint;


- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = [fmdb retain];
	}
	return self;
}

- (NSSet *)getStopTimeObjects:(NSNumber *)stop_id {
    return nil;
}

- (void)addStopTime:(StopTime *)stopTime
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into stop_times(trip_id,arrival_time,departure_time,stop_id,stop_sequence) values(?, ?, ?, ?, ?)",
     stopTime.trip_id,
     stopTime.arrival_time,
     stopTime.departure_time,
     stopTime.stop_id,
     stopTime.stop_sequence];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) cleanupAndCreate
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    //Drop table if it exists
    NSString *drop = @"DROP TABLE IF EXISTS stop_times";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'stop_times' ('trip_id' varchar(11) DEFAULT NULL, 'arrival_time' time DEFAULT NULL, 'departure_time' time DEFAULT NULL, 'stop_id' varchar(11) DEFAULT NULL, 'stop_sequence' int(11) DEFAULT NULL, 'is_timepoint' tinyint(1) DEFAULT NULL )";
    
    NSString *createIndex = @"CREATE INDEX stop_id_stop_times ON stop_times(stop_id)";
    NSString *createIndex1 = @"CREATE INDEX trip_id_stop_times ON stop_times(trip_id)";
    
    [db executeUpdate:create];
    [db executeUpdate:createIndex];
    [db executeUpdate:createIndex1];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) receiveRecord:(NSDictionary *)aRecord
{
    StopTime *stopTimeRecord = [[[StopTime alloc] init] autorelease];
    [stopTimeRecord setTrip_id:[aRecord objectForKey:@"trip_id"]];
    [stopTimeRecord setDeparture_time:[aRecord objectForKey:@"departure_time"]];
    [stopTimeRecord setArrival_time:[aRecord objectForKey:@"arrival_time"]];
    [stopTimeRecord setStop_id:[aRecord objectForKey:@"stop_id"]];
    [stopTimeRecord setStop_sequence:[aRecord objectForKey:@"stop_sequence"]];
    [self addStopTime:stopTimeRecord];
}

- (NSArray *) getStopsForTripId:(NSString *)tripId
{
    NSMutableArray *stops = [[[NSMutableArray alloc] init] autorelease];
    
    FMDatabase *localdb = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    
    [localdb setShouldCacheStatements:YES];
    if (![localdb open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return nil;
    }
    
    NSString *query = @"SELECT stop_id FROM stop_times WHERE trip_id=?";
    
    FMResultSet *rs = [localdb executeQuery:query, tripId];
    while ([rs next]) {
        [stops addObject:[rs stringForColumn:@"stop_id"]];
    }
    // close the result set.
    [rs close];
    [localdb close];
    
    //    NSLog(@"getStopTimesByTripId %d", [stop_times count]);
    return stops;
}

- (void) interpolateStopTimes
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    //First get all trip ids
    Trip *trip = [[Trip alloc] init];
    NSArray *tripIds = [trip getAllTripIds];
    [trip release];
    
    //for each trip id interpolate stop times and update database
    for (NSString *tripId in tripIds) {
        [self updateStopTimes:[self getTimeInterpolatedStopTimesByTripId:tripId]];
    }
}

- (NSArray *) getTimeInterpolatedStopTimesByTripId:(NSString *)tripId
{
    NSMutableArray *stop_times_i = [[[NSMutableArray alloc] init] autorelease];
    
    NSArray *stop_times = [self getStopTimesByTripId:tripId];
    // If there are no stoptimes [] is the correct return value but if the start
    // or end are missing times there is no correct return value.
    if (stop_times==nil || [stop_times count]==0)
        return nil;
    
    NSMutableDictionary *cur_timepoint=nil;
    NSMutableDictionary *next_timepoint = nil;
    double distance_between_timepoints = 0;
    double distance_traveled_between_timepoints = 0;
    
    for (int i=0; i < [stop_times count]; i++)
    {
        NSMutableDictionary *st = [stop_times objectAtIndex:i];
        if ([st objectForKey:@"arrival_time"] != nil && ![[st objectForKey:@"arrival_time"] isEqualToString:@""])
        {
            cur_timepoint = st;
            distance_between_timepoints = 0;
            distance_traveled_between_timepoints = 0;
            if (i + 1 < [stop_times count])
            {
                int k = i + 1;
                distance_between_timepoints += [Util ApproximateDistanceWithLat1:[[[stop_times objectAtIndex:k-1] objectForKey:@"stop_lat"] doubleValue] 
                                                                        withLon1:[[[stop_times objectAtIndex:k-1] objectForKey:@"stop_lon"] doubleValue] 
                                                                        withLat2:[[[stop_times objectAtIndex:k] objectForKey:@"stop_lat"] doubleValue] 
                                                                        withLon2:[[[stop_times objectAtIndex:k] objectForKey:@"stop_lon"] doubleValue]];
                while ([[stop_times objectAtIndex:k] objectForKey:@"arrival_time"] == nil || [[[stop_times objectAtIndex:k] objectForKey:@"arrival_time"] isEqualToString:@""])
                {
                    k += 1;
                    distance_between_timepoints += [Util ApproximateDistanceWithLat1:[[[stop_times objectAtIndex:k-1] objectForKey:@"stop_lat"] doubleValue] 
                                                                            withLon1:[[[stop_times objectAtIndex:k-1] objectForKey:@"stop_lon"] doubleValue] 
                                                                            withLat2:[[[stop_times objectAtIndex:k] objectForKey:@"stop_lat"] doubleValue] 
                                                                            withLon2:[[[stop_times objectAtIndex:k] objectForKey:@"stop_lon"] doubleValue]];
                }
                next_timepoint = [stop_times objectAtIndex:k];
            }
            NSMutableDictionary *temp_dict = [[[NSMutableDictionary alloc] init] autorelease];
            [temp_dict setObject:[Util TimeToSecondsSinceMidnight:[st objectForKey:@"arrival_time"]] forKey:@"arrival_time"];
            [temp_dict setObject:[st objectForKey:@"stop_id"] forKey:@"stop_id"];
            [temp_dict setObject:[st objectForKey:@"trip_id"] forKey:@"trip_id"];
            [temp_dict setObject:[st objectForKey:@"stop_sequence"] forKey:@"stop_sequence"];
            [temp_dict setObject:[NSNumber numberWithBool:YES] forKey:@"is_timepoint"];
            [stop_times_i addObject:temp_dict];
        }
        else
        {
            distance_traveled_between_timepoints += [Util ApproximateDistanceWithLat1:[[[stop_times objectAtIndex:i-1] objectForKey:@"stop_lat"] doubleValue] 
                                                                             withLon1:[[[stop_times objectAtIndex:i-1] objectForKey:@"stop_lon"] doubleValue] 
                                                                             withLat2:[[st objectForKey:@"stop_lat"] doubleValue] 
                                                                             withLon2:[[st objectForKey:@"stop_lon"] doubleValue]];
            float distance_percent = distance_traveled_between_timepoints / distance_between_timepoints;
            int next_time = [[Util TimeToSecondsSinceMidnight:[next_timepoint objectForKey:@"arrival_time"]] intValue];
            int cur_time = [[Util TimeToSecondsSinceMidnight:[cur_timepoint objectForKey:@"arrival_time"]] intValue];
            int total_time = next_time - cur_time;
//            NSLog(@"next- %d, cur - %d, total - %d, cur_timepoint- %@, D: %f, %f", next_time, cur_time, total_time, [cur_timepoint objectForKey:@"arrival_time"], distance_between_timepoints, distance_traveled_between_timepoints);
            float time_estimate = distance_percent * total_time + [[Util TimeToSecondsSinceMidnight:[cur_timepoint objectForKey:@"arrival_time"]] intValue];
            NSMutableDictionary *temp_dict = [[NSMutableDictionary alloc] init];
            [temp_dict setObject:[NSNumber numberWithInt:(int)round(time_estimate)] forKey:@"arrival_time"];
            [temp_dict setObject:[st objectForKey:@"stop_id"] forKey:@"stop_id"];
            [temp_dict setObject:[st objectForKey:@"trip_id"] forKey:@"trip_id"];
            [temp_dict setObject:[st objectForKey:@"stop_sequence"] forKey:@"stop_sequence"];
            [temp_dict setObject:[NSNumber numberWithBool:NO] forKey:@"is_timepoint"];
            [stop_times_i addObject:temp_dict];
            [temp_dict release];
        }
    }
    
    //    NSLog(@"getTimeInterpolatedStopTimesByTripId %d", [stop_times_i count]);
    return stop_times_i;
}

- (NSArray *) getStopTimesByTripId:(NSString *)tripId
{
    NSMutableArray *stop_times = [[[NSMutableArray alloc] init] autorelease];
    
    NSString *query = @"SELECT stops.stop_lat, stops.stop_lon, stop_times.trip_id, stop_times.arrival_time, stop_times.stop_id, stop_times.stop_sequence FROM stop_times, stops WHERE stop_times.trip_id=? AND stops.stop_id=stop_times.stop_id ORDER BY stop_times.stop_sequence";
    
    FMResultSet *rs = [db executeQuery:query, tripId];
    while ([rs next]) {
        // just print out what we've got in a number of formats.
        NSMutableDictionary *stop_time = [[NSMutableDictionary alloc] init];
        
        [stop_time setObject:[rs objectForColumnName:@"stop_lat"] forKey:@"stop_lat"];
        [stop_time setObject:[rs objectForColumnName:@"stop_lon"] forKey:@"stop_lon"];
        [stop_time setObject:[rs objectForColumnName:@"stop_id"] forKey:@"stop_id"];
        [stop_time setObject:[rs objectForColumnName:@"trip_id"] forKey:@"trip_id"];
        [stop_time setObject:[rs objectForColumnName:@"arrival_time"] forKey:@"arrival_time"];
        [stop_time setObject:[rs objectForColumnName:@"stop_sequence"] forKey:@"stop_sequence"];
        
        [stop_times addObject:stop_time];
        [stop_time release];
    }
    // close the result set.
    [rs close];
    //    NSLog(@"getStopTimesByTripId %d", [stop_times count]);
    return stop_times;
}

- (void) updateStopTimes:(NSArray *)interpolatedStopTimes
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    [db beginTransaction];
    
    for (NSDictionary *stopTime in interpolatedStopTimes) {
        [db executeUpdate:@"UPDATE stop_times SET arrival_time=?, is_timepoint=? WHERE trip_id=? AND stop_id=? AND stop_sequence=?",
         [Util FormatSecondsSinceMidnight:[stopTime objectForKey:@"arrival_time"]],
         [stopTime objectForKey:@"is_timepoint"],
         [stopTime objectForKey:@"trip_id"],
         [stopTime objectForKey:@"stop_id"],
         [stopTime objectForKey:@"stop_sequence"]];
    }
    
    [db commit];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) dealloc
{
    [db release];
    [arrival_time release];
    [departure_time release];
    [stop_id release];
    [stop_sequence release];
    [trip_id release];
    [is_timepoint release];
    [super dealloc];
}

@end
