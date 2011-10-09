//
//  FareRules.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface FareRules : NSObject {
    FMDatabase *db;
    NSString *fare_id;
    NSString *route_id;
    NSString *origin_id;
    NSString *destination_id;
    NSString *contains_id;
}

- (void)addFareRules:(FareRules *)value;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;


@property (nonatomic, retain) NSString *fare_id;
@property (nonatomic, retain) NSString *route_id;
@property (nonatomic, retain) NSString *origin_id;
@property (nonatomic, retain) NSString *destination_id;
@property (nonatomic, retain) NSString *contains_id;

@end
