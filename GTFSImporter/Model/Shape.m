//
//  Shape.m
//
//  Created by Kevin Conley on 6/25/2013.
//

#import "Shape.h"
#import "CSVParser.h"
#import "FMDatabase.h"
#import "Util.h"

@interface Shape ()
{
    FMDatabase *db;
}

@end

@implementation Shape

- (id)initWithDB:(FMDatabase *)fmdb
{
    self = [super init];
	if (self)
	{
		db = fmdb;
	}
	return self;
}

- (void)addShape:(Shape *)shape
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    [db executeUpdate:@"INSERT into shapes(shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence,shape_dist_traveled) values(?, ?, ?, ?, ?)",
     shape.shapeId,
     shape.shapePtLat,
     shape.shapePtLon,
     shape.shapePtSequence,
     shape.shapeDistTraveled];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
}

- (void)cleanupAndCreate
{
    if (db==nil) {
        db = [FMDatabase databaseWithPath:[Util getDatabasePath]];
        if (![db open]) {
            NSLog(@"Could not open db.");
            return;
        }
    }
    
    //Drop table if it exists
    NSString *dropShape = @"DROP TABLE IF EXISTS shapes";
    
    [db executeUpdate:dropShape];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
    
    //Create table
    NSString *createShape = @"CREATE TABLE 'shapes' ('shape_id' TEXT NOT NULL, 'shape_pt_lat' decimal(9,6) DEFAULT NULL, 'shape_pt_lon' decimal(9,6) DEFAULT NULL, 'shape_pt_sequence' INTEGER NOT NULL, 'shape_dist_traveled' decimal(9,6) DEFAULT NULL)";
    
    NSString *createIndex = @"CREATE INDEX shape_id_shape ON shapes(shape_id)";
    
    [db executeUpdate:createShape];
    [db executeUpdate:createIndex];
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        return;
    }
}

- (void)receiveRecord:(NSDictionary *)aRecord
{
    
    Shape *shapeRecord = [[Shape alloc] init];
    shapeRecord.shapeId = aRecord[@"shape_id"];
    shapeRecord.shapePtLat = aRecord[@"shape_pt_lat"];
    shapeRecord.shapePtLon = aRecord[@"shape_pt_lon"];
    shapeRecord.shapePtSequence = aRecord[@"shape_pt_sequence"];
    shapeRecord.shapeDistTraveled = aRecord[@"shape_dist_traveled"];
    
    [self addShape:shapeRecord];
}



@end
