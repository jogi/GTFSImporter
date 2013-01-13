//
//  FareRules.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "FareRules.h"
#import "CSVParser.h"
#import "FMDatabase.h"
#import "Util.h"

@interface FareRules ()
{
    FMDatabase *db;
}

@end

@implementation FareRules

- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addFareRules:(FareRules *)value {
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into fare_rules(fare_id,route_id,origin_id,destination_id,contains_id) values(?, ?, ?, ?, ?)",
     value.fareId,
     value.routeId,
     value.originId,
     value.destinationId,
     value.containsId];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS fare_rules";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'fare_rules' ('fare_id' varchar(11) NOT NULL, 'route_id' varchar(11) NOT NULL, 'origin_id' varchar(11) NOT NULL, 'destination_id' varchar(11) NOT NULL, 'contains_id' varchar(11) NOT NULL)";
    
    [db executeUpdate:create];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    FareRules *fareRulesRecord = [[FareRules alloc] init];
    fareRulesRecord.fareId = aRecord[@"fare_id"];
    fareRulesRecord.routeId = aRecord[@"route_id"];
    fareRulesRecord.originId = aRecord[@"origin_id"];
    fareRulesRecord.destinationId = aRecord[@"destination_id"];
    fareRulesRecord.containsId = aRecord[@"contains_id"];
    
    [self addFareRules:fareRulesRecord];
}


@end
