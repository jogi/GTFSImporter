//
//  Trip.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Trip.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Util.h"

@implementation Trip
@synthesize trip_headsign, trip_id, route_id, service_id, block_id, direction_id;


- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = [fmdb retain];
	}
	return self;
}

- (void)addTrip:(Trip *)trip
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into trips(block_id,route_id,direction_id,trip_headsign,service_id,trip_id) values(?, ?, ?, ?, ?, ?)",
     trip.block_id,
     trip.route_id,
     trip.direction_id,
     trip.trip_headsign,
     trip.service_id,
     trip.trip_id];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS trips";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'trips' ('block_id' varchar(11) DEFAULT NULL, 'route_id' varchar(11) DEFAULT NULL, 'direction_id' tinyint(1) DEFAULT NULL, 'trip_headsign' varchar(255) DEFAULT NULL, 'service_id' varchar(11) DEFAULT NULL, 'trip_id' varchar(11) NOT NULL, PRIMARY KEY ('trip_id'))";
    
    [db executeUpdate:create];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) receiveRecord:(NSDictionary *)aRecord
{
    Trip *tripRecord = [[[Trip alloc] init] autorelease];
    [tripRecord setBlock_id:[aRecord objectForKey:@"block_id"]];
    [tripRecord setRoute_id:[aRecord objectForKey:@"route_id"]];
    [tripRecord setDirection_id:[aRecord objectForKey:@"direction_id"]];
    [tripRecord setTrip_headsign:[aRecord objectForKey:@"trip_headsign"]];
    [tripRecord setService_id:[aRecord objectForKey:@"service_id"]];
    [tripRecord setTrip_id:[aRecord objectForKey:@"trip_id"]];
    [self addTrip:tripRecord];
}

- (NSArray *) getAllTripIds
{
    NSMutableArray *tripIds = [[[NSMutableArray alloc] init] autorelease];
    
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            db = nil;
            return nil;
        }
        
        db.shouldCacheStatements=YES;
    }
    
    NSString *query = @"SELECT trip_id from trips";
    
    FMResultSet *rs = [db executeQuery:query];
    while ([rs next]) {
        [tripIds addObject:[rs objectForColumnName:@"trip_id"]];
    }
    // close the result set.
    [rs close];
    [db close];
    
    //    NSLog(@"getStopTimesByTripId %d", [stop_times count]);
    return tripIds;
}

- (void) dealloc
{
    [db release];
    [trip_id release];
    [trip_headsign release];
    [route_id release];
    [service_id release];
    [direction_id release];
    [block_id release];
    [super dealloc];
}

@end
