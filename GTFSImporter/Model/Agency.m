//
//  Agency.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Agency.h"
#import "CSVParser.h"
#import "FMDatabase.h"
#import "Util.h"

@interface Agency ()
{
    FMDatabase *db;
}

@end

@implementation Agency

- (id)initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
    if (self)
    {
        db = fmdb;
    }
    return self;
}

- (void)addAgency:(Agency *)agency
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }

    [db executeUpdate:@"INSERT into agency(agency_id, agency_name, agency_url, agency_timezone, agency_lang, agency_phone) values(?, ?, ?, ?, ?, ?)",
                        agency.agencyId,
                        agency.agencyName,
                        agency.agencyUrl,
                        agency.agencyTimezone,
                        agency.agencyLang,
                        agency.agencyPhone];

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
    NSString *dropAgency = @"DROP TABLE IF EXISTS agency";

    [db executeUpdate:dropAgency];

    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }

    //Create table
    NSString *createAgency = @"CREATE TABLE 'agency' ('agency_url' varchar(255) DEFAULT NULL, 'agency_name' varchar(255) DEFAULT NULL, 'agency_timezone' varchar(50) DEFAULT NULL, 'agency_lang' char(2) DEFAULT NULL, 'agency_phone' varchar(50) DEFAULT NULL, 'agency_id' varchar(50) DEFAULT NULL)";

    [db executeUpdate:createAgency];

    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{

    Agency *agencyRecord = [[Agency alloc] init];
    agencyRecord.agencyId = aRecord[@"agency_id"];
    agencyRecord.agencyName = aRecord[@"agency_name"];
    agencyRecord.agencyUrl = aRecord[@"agency_url"];
    agencyRecord.agencyTimezone = aRecord[@"agency_timezone"];
    agencyRecord.agencyLang = aRecord[@"agency_lang"];
    agencyRecord.agencyPhone = aRecord[@"agency_phone"];

    [self addAgency:agencyRecord];
}



@end
