//
//  FareAttributes.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Adobe Systems Inc. All rights reserved.
//

#import "FareAttributes.h"
#import "CSVParser.h"
#import "FMDatabase.h"


@implementation FareAttributes
@synthesize currency_type, fare_id, payment_method, price, transfer_duration, transfers;

- (id) initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = [fmdb retain];
	}
	return self;
}

- (void)addFareAttributesObject:(FareAttributes *)value {
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                           stringByAppendingPathComponent:@"vta_gtfs.db"]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            [db release];
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into fare_attributes(fare_id,price,currency_type,payment_method,transfers,transfer_duration) values(?, ?, ?, ?, ?, ?)",
                        value.fare_id,
                        value.price,
                        value.currency_type,
                        value.payment_method,
                        value.transfers,
                        value.transfer_duration];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS fare_attributes";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'fare_attributes' ('fare_id' INT(11) NOT NULL, 'price' FLOAT DEFAULT 0.0, 'currency_type' varchar(255) DEFAULT NULL, 'payment_method' INT(2), 'transfers' INT(11), 'transfer_duration' INT(11), PRIMARY KEY ('fare_id'))";
    
    [db executeUpdate:create];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void) receiveRecord:(NSDictionary *)aRecord
{
    FareAttributes *fareAttributesRecord = [[[FareAttributes alloc] init] autorelease];
    [fareAttributesRecord setValuesForKeysWithDictionary:aRecord];
    [self addFareAttributesObject:fareAttributesRecord];
}

- (void) dealloc
{
    [db release];
    [fare_id release];
    [currency_type release];
    [payment_method release];
    [price release];
    [transfers release];
    [transfer_duration release];
    [super dealloc];
}

@end
