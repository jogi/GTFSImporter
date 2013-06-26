//
//  CalendarDate.m
//
//  Created by Kevin Conley on 6/25/2013.
//

#import "CalendarDate.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Util.h"

@interface CalendarDate ()
{
    FMDatabase *db;
    NSDateFormatter *dateFormat, *dateFormat2;
}

@end

@implementation CalendarDate

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

- (void)addCalendarDate:(CalendarDate *)calendarDate
{    
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into calendar_dates(service_id,date,exception_type) values(?, ?, ?)",
     calendarDate.serviceId,
     calendarDate.date,
     calendarDate.exceptionType];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS calendar_dates";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'calendar_dates' ('service_id' varchar(20) NOT NULL,'date' date NOT NULL,'exception_type' tinyint(2) NOT NULL)";
    NSString *createIndex = @"CREATE INDEX service_id_calendar_dates ON calendar_dates(service_id)";
    
    [db executeUpdate:create];
    [db executeUpdate:createIndex];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    
    CalendarDate *calendarDateRecord = [[CalendarDate alloc] init];
    calendarDateRecord.serviceId = aRecord[@"service_id"];
    calendarDateRecord.exceptionType = aRecord[@"exception_type"];
    //Date format is wrong, so correct it now
    calendarDateRecord.date = [dateFormat2 stringFromDate:[dateFormat dateFromString:aRecord[@"date"]]];
    
    [self addCalendarDate:calendarDateRecord];
}


@end
