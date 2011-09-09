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
#import "Route.h"
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;
    NSString *inputPath = [[Util getTransitFilesBasepath] stringByAppendingPathComponent:file];
	NSString *csvString = [NSString stringWithContentsOfFile:inputPath encoding:NSUTF8StringEncoding error:&error];
    
	if (!csvString)
	{
		NSLog(@"Couldn't read file at path %s\n. Error: %s",
              [inputPath UTF8String],
              [[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
		[pool drain];
		exit(1);
	}
    return csvString;
}

- (int) addCalendar
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"calendar.txt"];
    
    Calendar *cal = [[[Calendar alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [cal cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:cal selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"Calendar entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (int) addAgency
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    
    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"agency.txt"];
    
    Agency *agency = [[[Agency alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [agency cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:agency selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"Agency entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (int) addFareAttributes
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"fare_attributes.txt"];
    
    FareAttributes *fareAttributes = [[[FareAttributes alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [fareAttributes cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:fareAttributes selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"FareAttributes entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (int) addFareRules
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"fare_rules.txt"];
    
    FareRules *fareRules = [[[FareRules alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [fareRules cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:fareRules selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"FareRules entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (int) addRoute
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"routes.txt"];
    
    Route *route = [[[Route alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [route cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:route selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"Route entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (int) addStop
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"stops.txt"];
    
    Stop *stop = [[[Stop alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [stop cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:stop selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"Stop entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (int) addStopRoutes
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    
    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
    
    Stop *stop = [[[Stop alloc] initWithDB:db] autorelease];
    
	[stop updateRoutes];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"Stop entries successfully updated with routes in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (int) addStopTime
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"stop_times.txt"];
    
    StopTime *stopTime = [[[StopTime alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [stopTime cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:stopTime selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"StopTime entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
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
    
    [stopTime release];
	
    return 0;
}

- (int) addTrip
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *startDate = [NSDate date];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Util getDatabasePath]];

    [db setShouldCacheStatements:YES];
    if (![db open]) {
        NSLog(@"Could not open db.");
        //[db release];
        return 1;
    }
	
    NSString *csvString = [self parseForFile:@"trips.txt"];
    
    Trip *trip = [[[Trip alloc] initWithDB:db] autorelease];
    
	CSVParser *parser =
    [[[CSVParser alloc]
      initWithString:csvString
      separator:@","
      hasHeader:YES
      fieldNames:nil] autorelease];
    
    [trip cleanupAndCreate];
    [db beginTransaction];
    [parser parseRowsForReceiver:trip selector:@selector(receiveRecord:)];
    [db commit];
    
	NSDate *endDate = [NSDate date];
    
	NSLog(@"Trip entries successfully imported in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
    [pool drain];
	
    return 0;
}

- (void) sanitizeData
{
    Transformations *transformations = [[Transformations alloc] init];
    [transformations applyTransformationsFromCSV];
    [transformations release];
}


- (void) vacuum
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
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
    [pool drain];

}

- (void) reindex
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
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
    [pool drain];
    
}


@end
