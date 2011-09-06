//
//  Transformations.m
//  San Jose Transit GTFS
//
//  Created by Vashishtha Jogi on 8/26/11.
//  Copyright 2011 Adobe Systems Inc. All rights reserved.
//

#import "Transformations.h"
#import "FMDatabase.h"
#import "CSVParser.h"

@implementation Transformations

-(void) applyTransformationsFromCSV
{
    NSString *basePath = @"/Volumes/Data/Projects/San Jose Transit/google_transit/db";
    //Open db connection first
    db = [FMDatabase databaseWithPath:[basePath stringByAppendingPathComponent:@"vta_gtfs.db"]];
    
    if (![db open]) {
        NSLog(@"Could not open db.");
        [db release];
        return;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;

    NSString *inputPath = [basePath stringByAppendingPathComponent:@"transformations.txt"];
	NSString *csvString = [NSString stringWithContentsOfFile:inputPath encoding:NSUTF8StringEncoding error:&error];
    
	if (!csvString)
	{
		NSLog(@"Couldn't read file at path %s\n. Error: %s",
              [inputPath UTF8String],
              [[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
		[pool drain];
		exit(1);
	}
	
	NSDate *startDate = [NSDate date];
	
	CSVParser *parser =[[[CSVParser alloc] initWithString:csvString separator:@";" hasHeader:NO fieldNames:nil] autorelease];
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
    [pool release];
}

@end
