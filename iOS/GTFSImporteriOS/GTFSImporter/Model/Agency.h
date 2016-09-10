//
//  Agency.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"


@interface Agency : NSObject

@property (nonatomic, strong) NSString * agencyId;
@property (nonatomic, strong) NSString * agencyName;
@property (nonatomic, strong) NSString * agencyTimezone;
@property (nonatomic, strong) NSString * agencyUrl;

- (void)addAgency:(Agency *)agency;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;

@end
