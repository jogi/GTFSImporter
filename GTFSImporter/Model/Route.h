//
//  Route.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface Route : NSObject

@property (nonatomic, strong) NSString * routeLongName;
@property (nonatomic, strong) NSNumber * routeType;
@property (nonatomic, strong) NSString * routeId;
@property (nonatomic, strong) NSString * routeShortName;
@property (nonatomic, strong) NSString * routeUrl;
@property (nonatomic, strong) NSString * routeColor;
@property (nonatomic, strong) NSString * routeTextColor;
@property (nonatomic, strong) NSString * agencyId;

- (void)addRoute:(Route *)route;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;
- (NSArray *)getAllRoutes;

@end
