//
//  FareAttributes.h
//  GTFS-VTA
//
//  Created by Vashishtha Jogi on 7/31/11.
//  Copyright (c) 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface FareAttributes : NSObject

@property (nonatomic, strong) NSString * currencyType;
@property (nonatomic, strong) NSString * fareId;
@property (nonatomic, strong) NSNumber * paymentMethod;
@property (nonatomic, strong) NSNumber * price;
@property (nonatomic, strong) NSNumber * transferDuration;
@property (nonatomic, strong) NSNumber * transfers;

- (void)addFareAttributesObject:(FareAttributes *)value;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;

@end
