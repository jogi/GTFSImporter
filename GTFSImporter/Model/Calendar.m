//
//  Calendar.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Calendar.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Util.h"

@interface Calendar ()
{
    FMDatabase *db;
    NSDateFormatter *dateFormat, *dateFormat2;
}

@end

@implementation Calendar

- (id)initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyyMMdd"];
        dateFormat2 = [[NSDateFormatter alloc] init];
        [dateFormat2 setDateFormat:@"yyyy-MM-dd"];
	}
	return self;
}

- (void)addCalendar:(Calendar *)calendar
{
//    NSLog(@"Calendar %@, %@", calendar.start_date, calendar.end_date);
    
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into calendar(end_date, friday, monday, saturday, service_id, start_date, sunday, thursday, tuesday, wednesday) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
     calendar.endDate,
     calendar.friday,
     calendar.monday,
     calendar.saturday,
     calendar.serviceId,
     calendar.startDate,
     calendar.sunday,
     calendar.thursday,
     calendar.tuesday,
     calendar.wednesday];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS calendar";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'calendar' ('service_id' varchar(20) DEFAULT NULL,'start_date' date DEFAULT NULL,'end_date' date DEFAULT NULL,'monday' tinyint(1) DEFAULT NULL,'tuesday' tinyint(1) DEFAULT NULL,'wednesday' tinyint(1) DEFAULT NULL,'thursday' tinyint(1) DEFAULT NULL,'friday' tinyint(1) DEFAULT NULL,'saturday' tinyint(1) DEFAULT NULL,'sunday' tinyint(1) DEFAULT NULL)";
    NSString *createIndex = @"CREATE INDEX service_id_calendar ON calendar(service_id)";
    
    [db executeUpdate:create];
    [db executeUpdate:createIndex];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    
    Calendar *calendarRecord = [[Calendar alloc] init];
    calendarRecord.serviceId = aRecord[@"service_id"];
    calendarRecord.sunday = aRecord[@"sunday"];
    calendarRecord.monday = aRecord[@"monday"];
    calendarRecord.tuesday = aRecord[@"tuesday"];
    calendarRecord.wednesday = aRecord[@"wednesday"];
    calendarRecord.thursday = aRecord[@"thursday"];
    calendarRecord.friday = aRecord[@"friday"];
    calendarRecord.saturday = aRecord[@"saturday"];
    //Date format is wrong, so correct it now
    calendarRecord.startDate = [dateFormat2 stringFromDate:[dateFormat dateFromString:aRecord[@"start_date"]]];
    calendarRecord.endDate = [dateFormat2 stringFromDate:[dateFormat dateFromString:aRecord[@"end_date"]]];
    
    [self addCalendar:calendarRecord];
}


@end
