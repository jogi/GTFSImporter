//
//  Util.m
//  GTFSImporter
//
//  Created by Vashishtha Jogi on 9/7/11.
//  Copyright 2011 Adobe Systems. All rights reserved.
//

#import "Util.h"

@implementation Util

+ (NSString *) getTransitFilesBasepath
{
    return @"/Volumes/Data/Projects/San Jose Transit/google_transit";
}

+ (NSString *) getTransformationsFilePath
{
    return @"/Volumes/Data/Projects/San Jose Transit/google_transit/db/transformations.txt";
}

+ (NSString *) getDatabasePath
{
    return @"/Volumes/Data/Projects/San Jose Transit/google_transit/db/vta_gtfs.db";
}

@end
