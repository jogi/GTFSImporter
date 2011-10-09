//
//  Trip.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface Trip : NSObject {
    FMDatabase *db;
    NSString * trip_headsign;
    NSString * trip_id;
    NSString * route_id;
    NSString * service_id;
    NSString * block_id;
    NSNumber * direction_id;

}

@property (nonatomic, retain) NSString * trip_headsign;
@property (nonatomic, retain) NSString * trip_id;
@property (nonatomic, retain) NSString * route_id;
@property (nonatomic, retain) NSString * service_id;
@property (nonatomic, retain) NSString * block_id;
@property (nonatomic, retain) NSNumber * direction_id;

- (void)addTrip:(Trip *)trip;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;
- (NSArray *) getAllTripIds;

@end
