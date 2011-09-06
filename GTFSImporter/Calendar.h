//
//  Calendar.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Adobe Systems Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"


@interface Calendar : NSObject {
    FMDatabase *db;
    NSString * end_date;
    NSString * friday;
    NSString * monday;
    NSString * saturday;
    NSNumber * service_id;
    NSString * start_date;
    NSString * sunday;
    NSString * thursday;
    NSString * tuesday;
    NSString * wednesday;
    NSDateFormatter *dateFormat;
    NSDateFormatter *dateFormat2;

}
@property (nonatomic, retain) NSString * end_date;
@property (nonatomic, retain) NSString * friday;
@property (nonatomic, retain) NSString * monday;
@property (nonatomic, retain) NSString * saturday;
@property (nonatomic, retain) NSNumber * service_id;
@property (nonatomic, retain) NSString * start_date;
@property (nonatomic, retain) NSString * sunday;
@property (nonatomic, retain) NSString * thursday;
@property (nonatomic, retain) NSString * tuesday;
@property (nonatomic, retain) NSString * wednesday;
@property (nonatomic, retain) NSDateFormatter *dateFormat;
@property (nonatomic, retain) NSDateFormatter *dateFormat2;

- (id) initWithDB:(FMDatabase *)fmdb;
- (void) addCalendar:(Calendar *)calendar;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;

@end
