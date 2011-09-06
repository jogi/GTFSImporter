//
//  Agency.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Adobe Systems Inc. All rights reserved.
//

#import "Agency.h"
#import "CSVParser.h"
#import "FMDatabase.h"


@implementation Agency
@synthesize agency_id;
@synthesize agency_name;
@synthesize agency_timezone;
@synthesize agency_url;

- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = [fmdb retain];
	}
	return self;
}

- (void) addAgency:(Agency *)agency
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                           stringByAppendingPathComponent:@"vta_gtfs.db"]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into agency(agency_id, agency_name, agency_timezone, agency_url) values(?, ?, ?, ?)",
                        agency.agency_id,
                        agency.agency_name,
                        agency.agency_timezone,
                        agency.agency_url];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
}

- (void) cleanupAndCreate
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                           stringByAppendingPathComponent:@"vta_gtfs.db"]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    //Drop table if it exists
    NSString *dropAgency = @"DROP TABLE IF EXISTS agency";
    
    [db executeUpdate:dropAgency];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *createAgency = @"CREATE TABLE 'agency' ('agency_url' varchar(255) DEFAULT NULL, 'agency_name' varchar(255) DEFAULT NULL, 'agency_timezone' varchar(50) DEFAULT NULL, 'agency_id' varchar(50) NOT NULL, PRIMARY KEY ('agency_id'))";
    
    [db executeUpdate:createAgency];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) receiveRecord:(NSDictionary *)aRecord
{
    
    Agency *agencyRecord = [[Agency alloc] init];
    [agencyRecord setValuesForKeysWithDictionary:aRecord];
    [self addAgency:agencyRecord];
    [agencyRecord release];
}


- (void) dealloc
{
    [db release];
    [agency_id release];
    [agency_name release];
    [agency_timezone release];
    [agency_url release];
    [super dealloc];
}

@end
