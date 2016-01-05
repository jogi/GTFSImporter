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

@interface Trip ()
{
    FMDatabase *db;
}

@end

@implementation Trip

- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addTrip:(Trip *)trip
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into trips(block_id,route_id,direction_id,trip_headsign,service_id,trip_id,shape_id) values(?, ?, ?, ?, ?, ?, ?)",
     trip.blockId,
     trip.routeId,
     trip.directionId,
     trip.tripHeadsign,
     trip.serviceId,
     trip.tripId,
     trip.shapeId];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)cleanupAndCreate
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
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
    NSString *create = @"CREATE TABLE 'trips' ('block_id' TEXT DEFAULT NULL, 'route_id' TEXT DEFAULT NULL, 'direction_id' tinyint(1) DEFAULT NULL, 'trip_headsign' TEXT DEFAULT NULL, 'service_id' TEXT DEFAULT NULL, 'trip_id' TEXT NOT NULL, 'shape_id' TEXT NOT NULL, PRIMARY KEY ('trip_id'))";
    
    NSString *createIndex = @"CREATE INDEX route_id_trips ON trips(route_id)";
    
    [db executeUpdate:create];
    [db executeUpdate:createIndex];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    Trip *tripRecord = [[Trip alloc] init];
    tripRecord.blockId = aRecord[@"block_id"];
    tripRecord.routeId = aRecord[@"route_id"];
    tripRecord.serviceId = aRecord[@"service_id"];
    tripRecord.tripId = aRecord[@"trip_id"];
    tripRecord.shapeId = aRecord[@"shape_id"];
    
    if (aRecord[@"trip_headsign"]) {
        NSString *headsign = [[[aRecord[@"trip_headsign"] localizedCapitalizedString] stringByReplacingOccurrencesOfString:aRecord[@"route_id"] withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        tripRecord.tripHeadsign = headsign;
    }
    
    // if direction_id is empty, try to derive it
    if ([aRecord[@"direction_id"] length] == 0) {
        if ([aRecord[@"trip_headsign"] rangeOfString:@"NB"].location != NSNotFound || [aRecord[@"trip_headsign"] rangeOfString:@"WB"].location != NSNotFound) {
            tripRecord.directionId = @0;
        } else if ([aRecord[@"trip_headsign"] rangeOfString:@"SB"].location != NSNotFound || [aRecord[@"trip_headsign"] rangeOfString:@"EB"].location != NSNotFound) {
            tripRecord.directionId = @1;
        } else {
            tripRecord.directionId = @2;
        }
    } else {
        tripRecord.directionId = aRecord[@"direction_id"];
    }
    
    [self addTrip:tripRecord];
}

- (NSArray *)getAllTripIds
{
    NSMutableArray *tripIds = [[NSMutableArray alloc] init];
    
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


@end
