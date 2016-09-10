//
//  Transformations.m
//  San Jose Transit GTFS
//
//  Created by Vashishtha Jogi on 8/26/11.
//  Copyright 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "Transformations.h"
#import "FMDatabase.h"
#import "CSVParser.h"
#import "Util.h"

@interface Transformations ()
{
    FMDatabase *db;
}

@end

@implementation Transformations

-(void) applyTransformationsFromCSV
{
    //Open db connection first
    db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
    
    if (![db open]) {
        NSLog(@"Could not open db.");
        return;
    }
    
    NSError *error = nil;

    NSString *inputPath = [Util getTransformationsFilePath];
	NSString *csvString = [NSString stringWithContentsOfFile:inputPath encoding:NSUTF8StringEncoding error:&error];
    
	if (!csvString)
	{
		NSLog(@"Couldn't read file at path %s\n. Error: %s", [inputPath UTF8String], [[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
		exit(1);
	}
	
	NSDate *startDate = [NSDate date];
	
	CSVParser *parser =[[CSVParser alloc] initWithString:csvString separator:@";" hasHeader:NO fieldNames:nil];
    NSArray *parsed = [parser arrayOfParsedRows];
    
    
    
    for (NSDictionary *record in parsed)
    {
        for(int i=0;i<[record count];i++)
        {
            [db beginTransaction];
            [db executeUpdate:[record valueForKey:[NSString stringWithFormat:@"FIELD_%d", i+1]]];
            if ([db hadError]) {
                NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
            [db commit];
        }
    }
    
    NSDate *endDate = [NSDate date];
    
	NSLog(@"Transformations successfully done in %f seconds.", [endDate timeIntervalSinceDate:startDate]);
    
    [db close];
}

@end
