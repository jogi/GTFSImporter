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

@interface Stop ()
{
    FMDatabase *db;
}

@end

@implementation Stop

- (id)initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addStop:(Stop *)stop
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into stops(stop_lat,zone_id,stop_lon,stop_id,stop_desc,stop_name,location_type) values(?, ?, ?, ?, ?, ?, ?)",
     stop.stopLat,
     stop.zoneId,
     stop.stopLon,
     stop.stopId,
     stop.stopDesc,
     stop.stopName,
     stop.locationType];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS stops";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'stops' ('stop_lat' decimal(8,6) DEFAULT NULL, 'zone_id' varchar(11) DEFAULT NULL, 'stop_lon' decimal(9,6) DEFAULT NULL, 'stop_id' varchar(11) NOT NULL, 'stop_desc' varchar(255) DEFAULT NULL, 'stop_name' varchar(255) DEFAULT NULL, 'location_type' int(2) DEFAULT NULL, 'routes' varchar(255) DEFAULT NULL, PRIMARY KEY ('stop_id'))";
    
    NSString *createIndex = @"CREATE INDEX stop_lat_lon_stops ON stops(stop_lat, stop_lon)";
    
    [db executeUpdate:create];
    [db executeUpdate:createIndex];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    Stop *stopRecord = [[Stop alloc] init];
    stopRecord.stopId = aRecord[@"stop_id"];
    stopRecord.stopLat = aRecord[@"stop_lat"];
    stopRecord.stopLon = aRecord[@"stop_lon"];
    stopRecord.stopName = aRecord[@"stop_name"];
    stopRecord.stopDesc = aRecord[@"stop_desc"];
    stopRecord.zoneId = aRecord[@"zone_id"];
    stopRecord.locationType = aRecord[@"location_type"];
    
    [self addStop:stopRecord];
}

- (void)updateStopWithRoutes:(NSArray *)route withStopId:(NSString *)stopId
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
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

- (void)updateRoutes
{
    @autoreleasepool {
        NSMutableDictionary *stopWithRoutes = [[NSMutableDictionary alloc] init];
        //First get all unique route trips
        Route *route = [[Route alloc] init];
        NSArray *routeArray = [route getAllRoutes];
        StopTime *stopTime = [[StopTime alloc] init];
        
        for (NSDictionary *route in routeArray) {
            NSArray *stops = [stopTime getStopsForTripId:route[@"trip_id"]];
            for (NSString *stopId in stops) {
                if (stopWithRoutes[stopId]==nil) {
                    [stopWithRoutes setValue:[[NSMutableArray alloc] init] forKey:stopId];
                }
                if ([stopWithRoutes[stopId] containsObject:route[@"route_short_name"]] == NO) {
                    [stopWithRoutes[stopId] addObject:route[@"route_short_name"]];
                }
            }
        }
        
        
 //   NSLog(@"%@, %lu", stopWithRoutes, [stopWithRoutes count]);
        
        for (NSString *key in [stopWithRoutes allKeys]) {
//        NSLog(@"%@ - %@", key, [[stopWithRoutes objectForKey:key] componentsJoinedByString:@","]);
            [self updateStopWithRoutes:stopWithRoutes[key] withStopId:key];
        }
    }
}


@end
