//
//  Calendar.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"


@interface Calendar : NSObject

@property (nonatomic, strong) NSString * endDate;
@property (nonatomic, strong) NSString * friday;
@property (nonatomic, strong) NSString * monday;
@property (nonatomic, strong) NSString * saturday;
@property (nonatomic, strong) NSString * serviceId;
@property (nonatomic, strong) NSString * startDate;
@property (nonatomic, strong) NSString * sunday;
@property (nonatomic, strong) NSString * thursday;
@property (nonatomic, strong) NSString * tuesday;
@property (nonatomic, strong) NSString * wednesday;

- (id)initWithDB:(FMDatabase *)fmdb;
- (void)addCalendar:(Calendar *)calendar;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;

@end
