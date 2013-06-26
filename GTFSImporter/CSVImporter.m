//
//  CSVImporter.m
//  San Jose Transit GTFS
//
//  Created by Vashishtha Jogi on 8/27/11.
//  Copyright 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "CSVImporter.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Agency.h"
#import "FareAttributes.h"
#import "FareRules.h"
#import "Calendar.h"
#import "CalendarDate.h"
#import "Route.h"
#import "Shape.h"
#import "Stop.h"
#import "Trip.h"
#import "StopTime.h"
#import "Transformations.h"
#import "Util.h"

@implementation CSVImporter

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }

    return self;
}

- (NSString *)parseForFile:(NSString *)file
{
    NSError *error = nil;
    NSString *inputPath = [[Util getTransitFilesBasepath] stringByAppendingPathComponent:file];
    NSString *csvString = [NSString stringWithContentsOfFile:inputPath encoding:NSUTF8StringEncoding error:&error];

    if (!csvString)
    {
        NSLog(@"Couldn't read file at path %s\n. Error: %s", [inputPath UTF8String], [[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
    }
    return csvString;
}

- (int) addCalendar
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"calendar"];

    Calendar *cal = [[Calendar alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [cal cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:cal selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"Calendar entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addCalendarDate
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"calendar_dates"];

    CalendarDate *calDate = [[CalendarDate alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
     initWithString:csvString
     separator:@","
     hasHeader:YES
     fieldNames:nil];

    [calDate cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:calDate selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"Calendar Dates entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}


- (int) addAgency
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"agency"];

    Agency *agency = [[Agency alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [agency cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:agency selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"Agency entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addFareAttributes
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"fare_attributes"];

    FareAttributes *fareAttributes = [[FareAttributes alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [fareAttributes cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:fareAttributes selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"FareAttributes entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];
    return 0;
}

- (int) addFareRules
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"fare_rules"];

    FareRules *fareRules = [[FareRules alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [fareRules cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:fareRules selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"FareRules entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addRoute
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"routes"];

    Route *route = [[Route alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [route cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:route selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"Route entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addShape
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"shapes"];

    Shape *shape = [[Shape alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
     initWithString:csvString
     separator:@","
     hasHeader:YES
     fieldNames:nil];

    [shape cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:shape selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"Shape entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addStop
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"stops"];

    Stop *stop = [[Stop alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [stop cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:stop selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"Stop entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addStopRoutes
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    Stop *stop = [[Stop alloc] initWithDB:db];

    [stop updateRoutes];

    NSDate *endDate = [NSDate date];

    NSLog(@"Stop entries successfully updated with routes in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addStopTime
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"stop_times"];

    StopTime *stopTime = [[StopTime alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [stopTime cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:stopTime selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"StopTime entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (int) addInterpolatedStopTime
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    StopTime *stopTime = [[StopTime alloc] initWithDB:db];

    [stopTime interpolateStopTimes];

    NSDate *endDate = [NSDate date];

    NSLog(@"StopTime entries interpolated successfully in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];


    return 0;
}

- (int) addTrip
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }

    NSString *csvString = [self parseForFile:@"trips"];

    Trip *trip = [[Trip alloc] initWithDB:db];

    CSVParser *parser =
    [[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil];

    [trip cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:trip selector:@selector(receiveRecord:)];
    [db commit];

    NSDate *endDate = [NSDate date];

    NSLog(@"Trip entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);

    [db close];

    return 0;
}

- (void) sanitizeData
{
    Transformations *transformations = [[Transformations alloc] init];
    [transformations applyTransformationsFromCSV];
}


- (void) vacuum
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
    }

    [db executeUpdate:@"VACUUM"];

    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }

    NSDate *endDate = [NSDate date];

    NSLog(@"Vaccuuming done in %f seconds.", [endDate timeIntervalSinceDate:startDate]);


    [db close];
}

- (void) reindex
{
    NSDate *startDate = [NSDate date];

    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
    }

    [db executeUpdate:@"REINDEX"];

    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }

    NSDate *endDate = [NSDate date];

    NSLog(@"Reindexing done in %f seconds.", [endDate timeIntervalSinceDate:startDate]);


    [db close];
}


@end
