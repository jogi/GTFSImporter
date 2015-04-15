//
//  Route.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Route.h"
#import "CSVParser.h"
#import "FMDatabase.h"
#import "Util.h"

@interface Route ()
{
    FMDatabase *db;
}

@end

@implementation Route

- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addRoute:(Route *)route
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into routes(route_long_name,route_type,agency_id,route_id,route_short_name) values(?, ?, ?, ?, ?)",
     route.routeLongName,
     route.routeType,
     route.agencyId,
     route.routeId,
     route.routeShortName];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS routes";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'routes' ('route_long_name' varchar(255) DEFAULT NULL,'route_type' int(2) DEFAULT NULL, 'agency_id' varchar(11) DEFAULT NULL, 'route_id' varchar(11) NOT NULL, 'route_short_name' varchar(50) DEFAULT NULL, PRIMARY KEY ('route_id'))";
    
    [db executeUpdate:create];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    Route *routeRecord = [[Route alloc] init];
    routeRecord.routeId = aRecord[@"route_id"];
    routeRecord.routeLongName = [aRecord[@"route_long_name"] capitalizedString];
    routeRecord.routeShortName = [aRecord[@"route_short_name"] capitalizedString];
    routeRecord.routeType = aRecord[@"route_type"];
    routeRecord.agencyId = aRecord[@"agency_id"];
    
    [self addRoute:routeRecord];
}

- (NSArray *)getAllRoutes
{
    
    NSMutableArray *routes = [[NSMutableArray alloc] init];
    
    FMDatabase *localdb = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    
    [localdb setShouldCacheStatements:YES];
    if (![localdb open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return nil;
    }
    
    NSString *query = @"select routes.route_short_name, trips.route_id, trips.trip_headsign, trips.trip_id FROM routes, trips WHERE trips.route_id=routes.route_id";
    
    FMResultSet *rs = [localdb executeQuery:query];
    while ([rs next]) {
        // just print out what we've got in a number of formats.
        NSMutableDictionary *route = [[NSMutableDictionary alloc] init];
        route[@"route_id"] = [rs objectForColumnName:@"route_id"];
        route[@"trip_headsign"] = [rs objectForColumnName:@"trip_headsign"];
        route[@"trip_id"] = [rs objectForColumnName:@"trip_id"];
        route[@"route_short_name"] = [rs objectForColumnName:@"route_short_name"];
        
        
        [routes addObject:route];
        
    }
    // close the result set.
    [rs close];
    [localdb close];
    
    return routes;
    
}


@end
