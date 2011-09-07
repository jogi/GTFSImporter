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


@implementation Calendar
@synthesize end_date, friday, monday, saturday, service_id, start_date, sunday, thursday, tuesday, wednesday, dateFormat, dateFormat2;

- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = [fmdb retain];
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyyMMdd"];
        dateFormat2 = [[NSDateFormatter alloc] init];
        [dateFormat2 setDateFormat:@"yyyy-MM-dd"];
	}
	return self;
}

- (void) addCalendar:(Calendar *)calendar
{
//    NSLog(@"Calendar %@, %@", calendar.start_date, calendar.end_date);
    
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into calendar(end_date, friday, monday, saturday, service_id, start_date, sunday, thursday, tuesday, wednesday) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
     calendar.end_date,
     calendar.friday,
     calendar.monday,
     calendar.saturday,
     calendar.service_id,
     calendar.start_date,
     calendar.sunday,
     calendar.thursday,
     calendar.tuesday,
     calendar.wednesday];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS calendar";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'calendar' ('service_id' int(11) DEFAULT NULL,'start_date' date DEFAULT NULL,'end_date' date DEFAULT NULL,'monday' tinyint(1) DEFAULT NULL,'tuesday' tinyint(1) DEFAULT NULL,'wednesday' tinyint(1) DEFAULT NULL,'thursday' tinyint(1) DEFAULT NULL,'friday' tinyint(1) DEFAULT NULL,'saturday' tinyint(1) DEFAULT NULL,'sunday' tinyint(1) DEFAULT NULL)";
    NSString *createIndex = @"CREATE INDEX service_id_calendar ON calendar(service_id)";
    
    [db executeUpdate:create];
    [db executeUpdate:createIndex];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) receiveRecord:(NSDictionary *)aRecord
{
    
    Calendar *calendarRecord = [[Calendar alloc] init];
    [calendarRecord setService_id:[aRecord objectForKey:@"service_id"]];
    [calendarRecord setSunday:[aRecord objectForKey:@"sunday"]];
    [calendarRecord setMonday:[aRecord objectForKey:@"monday"]];
    [calendarRecord setTuesday:[aRecord objectForKey:@"tuesday"]];
    [calendarRecord setWednesday:[aRecord objectForKey:@"wednesday"]];
    [calendarRecord setThursday:[aRecord objectForKey:@"thursday"]];
    [calendarRecord setFriday:[aRecord objectForKey:@"friday"]];
    [calendarRecord setSaturday:[aRecord objectForKey:@"saturday"]];
    //Date format is wrong, so correct it now
    [calendarRecord setStart_date:[dateFormat2 stringFromDate:[dateFormat dateFromString:[aRecord objectForKey:@"start_date"]]]];
    [calendarRecord setEnd_date:[dateFormat2 stringFromDate:[dateFormat dateFromString:[aRecord objectForKey:@"end_date"]]]];
    
    [self addCalendar:calendarRecord];
    [calendarRecord release];
}

- (void) dealloc
{
    [db release];
    [dateFormat release];
    [dateFormat2 release];
    [end_date release];
    [start_date release];
    [service_id release];
    [monday release];
    [tuesday release];
    [wednesday release];
    [thursday release];
    [friday release];
    [saturday release];
    [sunday release];
    [super dealloc];
}

@end
