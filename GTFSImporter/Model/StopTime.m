//
//  StopTime.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Adobe Systems Inc. All rights reserved.
//

#import "StopTime.h"
#import "Trip.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Util.h"


@implementation StopTime
@synthesize arrival_time, departure_time, stop_sequence, trip_id, stop_id;


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
    NSString *create = @"CREATE TABLE 'stop_times' ('trip_id' int(11) DEFAULT NULL, 'arrival_time' time DEFAULT NULL, 'departure_time' time DEFAULT NULL, 'stop_id' int(11) DEFAULT NULL, 'stop_sequence' int(11) DEFAULT NULL)";
    
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

- (NSArray *) getStopsForTripId:(NSNumber *)tripId
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

- (void) dealloc
{
    [db release];
    [arrival_time release];
    [departure_time release];
    [stop_id release];
    [stop_sequence release];
    [trip_id release];
    [super dealloc];
}

@end
