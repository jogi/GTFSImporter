//
//  FareRules.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Adobe Systems Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface FareRules : NSObject {
    FMDatabase *db;
    NSNumber *fare_id;
    NSNumber *route_id;
    NSNumber *origin_id;
    NSNumber *destination_id;
    NSNumber *contains_id;
}

- (void)addFareRules:(FareRules *)value;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;


@property (nonatomic, retain) NSNumber *fare_id;
@property (nonatomic, retain) NSNumber *route_id;
@property (nonatomic, retain) NSNumber *origin_id;
@property (nonatomic, retain) NSNumber *destination_id;
@property (nonatomic, retain) NSNumber *contains_id;

@end
