//
//  Stop.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Stop.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Route.h"
#import "StopTime.h"
#import "Util.h"


@implementation Stop
@synthesize stop_lat, stop_lon, stop_id, stop_name, stop_desc, zone_id, location_type, routes;


- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = [fmdb retain];
	}
	return self;
}

- (void)addStop:(Stop *)stop
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into stops(stop_lat,zone_id,stop_lon,stop_id,stop_desc,stop_name,location_type) values(?, ?, ?, ?, ?, ?, ?)",
     stop.stop_lat,
     stop.zone_id,
     stop.stop_lon,
     stop.stop_id,
     stop.stop_desc,
     stop.stop_name,
     stop.location_type];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS stops";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'stops' ('stop_lat' decimal(8,6) DEFAULT NULL, 'zone_id' int(11) DEFAULT NULL, 'stop_lon' decimal(9,6) DEFAULT NULL, 'stop_id' int(11) NOT NULL, 'stop_desc' varchar(255) DEFAULT NULL, 'stop_name' varchar(255) DEFAULT NULL, 'location_type' int(2) DEFAULT NULL, 'routes' varchar(255) DEFAULT NULL, PRIMARY KEY ('stop_id'))";
    
    NSString *createIndex = @"CREATE INDEX stop_lat_lon_stops ON stops(stop_lat, stop_lon)";
    
    [db executeUpdate:create];
    [db executeUpdate:createIndex];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) receiveRecord:(NSDictionary *)aRecord
{
    Stop *stopRecord = [[[Stop alloc] init] autorelease];
    stopRecord.stop_id = [aRecord objectForKey:@"stop_id"];
    stopRecord.stop_lat = [aRecord objectForKey:@"stop_lat"];
    stopRecord.stop_lon = [aRecord objectForKey:@"stop_lon"];
    stopRecord.stop_name = [aRecord objectForKey:@"stop_name"];
    stopRecord.stop_desc = [aRecord objectForKey:@"stop_desc"];
    stopRecord.zone_id = [aRecord objectForKey:@"zone_id"];
    stopRecord.location_type = [aRecord objectForKey:@"location_type"];
    [self addStop:stopRecord];
}

- (void) updateStopWithRoutes:(NSArray *)route withStopId:(NSString *)stopId
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    NSString *routeString = [route componentsJoinedByString:@","];
    
    [db executeUpdate:@"UPDATE stops SET routes=? where stop_id=?",
     routeString,
     stopId];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) updateRoutes
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary *stopWithRoutes = [[NSMutableDictionary alloc] init];
    //First get all unique route trips
    Route *route = [[Route alloc] init];
    NSArray *routeArray = [route getAllRoutes];
    StopTime *stopTime = [[StopTime alloc] init];
    
    for (NSDictionary *route in routeArray) {
        NSArray *stops = [stopTime getStopsForTripId:[route objectForKey:@"trip_id"]];
        for (NSString *stopId in stops) {
            if ([stopWithRoutes objectForKey:stopId]==nil) {
                [stopWithRoutes setValue:[[[NSMutableArray alloc] init] autorelease] forKey:stopId];
            }
            if ([[stopWithRoutes objectForKey:stopId] containsObject:[route objectForKey:@"route_short_name"]] == NO) {
                [[stopWithRoutes objectForKey:stopId] addObject:[route objectForKey:@"route_short_name"]];
            }
        }
    }
    
    [stopTime release];
    [route release];
    
 //   NSLog(@"%@, %lu", stopWithRoutes, [stopWithRoutes count]);
    
    for (NSString *key in [stopWithRoutes allKeys]) {
//        NSLog(@"%@ - %@", key, [[stopWithRoutes objectForKey:key] componentsJoinedByString:@","]);
        [self updateStopWithRoutes:[stopWithRoutes objectForKey:key] withStopId:key];
    }
    [stopWithRoutes release];
    [pool drain];
}

- (void) dealloc
{
    [db release];
    [stop_id release];
    [stop_lat release];
    [stop_lon release];
    [stop_name release];
    [stop_desc release];
    [zone_id release];
    [location_type release];
    [routes release];
    [super dealloc];
}

@end
