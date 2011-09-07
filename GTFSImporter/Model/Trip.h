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
    NSNumber * trip_id;
    NSNumber * route_id;
    NSNumber * service_id;
    NSNumber * block_id;
    NSNumber * direction_id;

}

@property (nonatomic, retain) NSString * trip_headsign;
@property (nonatomic, retain) NSNumber * trip_id;
@property (nonatomic, retain) NSNumber * route_id;
@property (nonatomic, retain) NSNumber * service_id;
@property (nonatomic, retain) NSNumber * block_id;
@property (nonatomic, retain) NSNumber * direction_id;

- (void)addTrip:(Trip *)trip;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;

@end
