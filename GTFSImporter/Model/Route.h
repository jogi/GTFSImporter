//
//  Route.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface Route : NSObject {
    FMDatabase *db;
    NSString * route_long_name;
    NSNumber * route_type;
    NSString * route_id;
    NSString * route_short_name;
    NSString * agency_id;

}
@property (nonatomic, retain) NSString * route_long_name;
@property (nonatomic, retain) NSNumber * route_type;
@property (nonatomic, retain) NSString * route_id;
@property (nonatomic, retain) NSString * route_short_name;
@property (nonatomic, retain) NSString * agency_id;

- (void)addRoute:(Route *)route;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;
- (NSArray *) getAllRoutes;

@end
