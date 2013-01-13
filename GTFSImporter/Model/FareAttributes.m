//
//  FareAttributes.m
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import "FareAttributes.h"
#import "CSVParser.h"
#import "FMDatabase.h"
#import "Util.h"

@interface FareAttributes ()
{
    FMDatabase *db;
}

@end

@implementation FareAttributes

- (id)initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addFareAttributesObject:(FareAttributes *)value {
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into fare_attributes(fare_id,price,currency_type,payment_method,transfers,transfer_duration) values(?, ?, ?, ?, ?, ?)",
                        value.fareId,
                        value.price,
                        value.currencyType,
                        value.paymentMethod,
                        value.transfers,
                        value.transferDuration];
    
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
    NSString *drop = @"DROP TABLE IF EXISTS fare_attributes";
    
    [db executeUpdate:drop];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *create = @"CREATE TABLE 'fare_attributes' ('fare_id' varchar(11) NOT NULL, 'price' FLOAT DEFAULT 0.0, 'currency_type' varchar(255) DEFAULT NULL, 'payment_method' INT(2), 'transfers' INT(11), 'transfer_duration' INT(11), PRIMARY KEY ('fare_id'))";
    
    [db executeUpdate:create];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    FareAttributes *fareAttributesRecord = [[FareAttributes alloc] init];
    fareAttributesRecord.fareId = aRecord[@"fare_id"];
    fareAttributesRecord.price = aRecord[@"price"];
    fareAttributesRecord.currencyType = aRecord[@"currency_type"];
    fareAttributesRecord.paymentMethod = aRecord[@"payment_type"];
    fareAttributesRecord.transfers = aRecord[@"transfers"];
    fareAttributesRecord.transferDuration = aRecord[@"transfer_duration"];
    
    [self addFareAttributesObject:fareAttributesRecord];
}


@end
