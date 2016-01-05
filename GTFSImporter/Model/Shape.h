//
//  Shape.h
//
//  Created by Kevin Conley on 6/25/2013.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"


@interface Shape : NSObject

@property (nonatomic, strong) NSString * shapeId;
@property (nonatomic, strong) NSString * shapePtLat;
@property (nonatomic, strong) NSString * shapePtLon;
@property (nonatomic, strong) NSNumber * shapePtSequence;
@property (nonatomic, strong) NSNumber * shapeDistTraveled;


- (void)addShape:(Shape *)shape;
- (id)initWithDB:(FMDatabase *)fmdb;
- (void)cleanupAndCreate;
- (void)receiveRecord:(NSDictionary *)aRecord;

@end
