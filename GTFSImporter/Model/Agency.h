//
//  Agency.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"


@interface Agency : NSObject {
    FMDatabase *db;
    NSString *agency_id;
    NSString *agency_name;
    NSString *agency_timezone;
    NSString *agency_url;
}
@property (nonatomic, retain) NSString * agency_id;
@property (nonatomic, retain) NSString * agency_name;
@property (nonatomic, retain) NSString * agency_timezone;
@property (nonatomic, retain) NSString * agency_url;

- (void) addAgency:(Agency *)agency;
- (id) initWithDB:(FMDatabase *)fmdb;
- (void) cleanupAndCreate;
- (void) receiveRecord:(NSDictionary *)aRecord;

@end
