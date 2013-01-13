//
//  Trip.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface Trip : NSObject

@property (nonatomic, strong) NSString *tripHeadsign;
@property (nonatomic, strong) NSString *tripId;
@property (nonatomic, strong) NSString *routeId;
@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic, strong) NSString *blockId;
@property (nonatomic, strong) NSNumber *directionId;

- (void)addTrip:(Trip *)trip;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;
- (NSArray *)getAllTripIds;

@end
