//
//  FareAttributes.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface FareAttributes : NSObject {
    FMDatabase *db;
    NSString * currency_type;
    NSNumber * fare_id;
    NSNumber * payment_method;
    NSNumber * price;
    NSNumber * transfer_duration;
    NSNumber * transfers;
}
@property (nonatomic, retain) NSString * currency_type;
@property (nonatomic, retain) NSNumber * fare_id;
@property (nonatomic, retain) NSNumber * payment_method;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSNumber * transfer_duration;
@property (nonatomic, retain) NSNumber * transfers;

- (void)addFareAttributesObject:(FareAttributes *)value;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;

@end
