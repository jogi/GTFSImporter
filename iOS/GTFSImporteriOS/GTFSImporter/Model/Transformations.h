//
//  Transformations.h
//  San Jose Transit GTFS
//
//  Created by Vashishtha Jogi on 8/26/11.
//  Copyright 2011 Vashishtha Jogi Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface Transformations : NSObject

-(void) applyTransformationsFromCSV;

@end
