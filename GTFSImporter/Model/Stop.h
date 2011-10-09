//
//  Stop.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface Stop : NSObject {
    FMDatabase *db;
    NSNumber * stop_lat;
    NSNumber * stop_lon;
    NSString * stop_id;
    NSString * stop_name;
    NSString * stop_desc;
    NSNumber * location_type;
    NSString * zone_id;
    NSArray  * routes;
}
@property (nonatomic, retain) NSNumber * stop_lat;
@property (nonatomic, retain) NSNumber * stop_lon;
@property (nonatomic, retain) NSString * stop_id;
@property (nonatomic, retain) NSString * stop_name;
@property (nonatomic, retain) NSString * stop_desc;
@property (nonatomic, retain) NSNumber * location_type;
@property (nonatomic, retain) NSString * zone_id;
@property (nonatomic, retain) NSArray  * routes;

- (void)addStop:(Stop *)stop;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;
- (void) updateStopWithRoutes:(NSArray *)routes withStopId:(NSString *)stopId;
- (void) updateRoutes;

@end
