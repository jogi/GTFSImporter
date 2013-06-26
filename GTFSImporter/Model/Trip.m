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

    [db executeUpdate:@"INSERT into trips(block_id,route_id,direction_id,trip_headsign,service_id,shape_id,trip_id) values(?, ?, ?, ?, ?, ?, ?)",
     trip.blockId,
     trip.routeId,
     trip.directionId,
     trip.tripHeadsign,
     trip.serviceId,
     trip.shapeId,
     trip.tripId];

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
    NSString *create = @"CREATE TABLE 'trips' ('block_id' varchar(11) DEFAULT NULL, 'route_id' varchar(11) DEFAULT NULL, 'direction_id' tinyint(1) DEFAULT NULL, 'trip_headsign' varchar(255) DEFAULT NULL, 'service_id' varchar(11) DEFAULT NULL, 'shape_id' varchar(11) DEFAULT NULL, 'trip_id' varchar(11) NOT NULL, PRIMARY KEY ('trip_id'))";

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
    tripRecord.directionId = aRecord[@"direction_id"];
    tripRecord.tripHeadsign = aRecord[@"trip_headsign"];
    tripRecord.serviceId = aRecord[@"service_id"];
    tripRecord.shapeId = aRecord[@"shape_id"];
    tripRecord.tripId = aRecord[@"trip_id"];

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
