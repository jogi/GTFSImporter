//
//  FareRules.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface FareRules : NSObject

@property (nonatomic, strong) NSString *fareId;
@property (nonatomic, strong) NSString *routeId;
@property (nonatomic, strong) NSString *originId;
@property (nonatomic, strong) NSString *destinationId;
@property (nonatomic, strong) NSString *containsId;

- (void)addFareRules:(FareRules *)value;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;

@end
