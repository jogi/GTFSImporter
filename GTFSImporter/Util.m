//
//  Util.m
//  GTFSImporter
//
//  Created by Vashishtha Jogi on 9/7/11.
//  Copyright 2011 Vashishtha Jogi. All rights reserved.
//

#import "Util.h"

@implementation Util

/*
 This is root directory where all the gtfs files live. This directory will contain agency.txt, routes.txt, etc.
 */
+ (NSString *) getTransitFilesBasepath
{
    return @"/Volumes/Data/Projects/San Jose Transit/google_transit";
}

/*
 This is something new. After your data is imported, sqlite queries from this file will be executed on the imported data. You may want to delete any extraneous trips, or delete all trips before a certain date, etc. This is a comma separeted file with all queries. For an example see transformations.txt. If you dont need to apply any transformations, leave the file empty. Or if you dont want to apply the transformations just comment out the transformations call in main.m file.
 */
+ (NSString *) getTransformationsFilePath
{
    return @"/Volumes/Data/Projects/San Jose Transit/google_transit/db/transformations.txt";
}

/*
 The path where the database will be created. The file is created for you if it does not exist. But the directory in which the file will be created needs to pre-exist.
 */
+ (NSString *) getDatabasePath
{
    return @"/Volumes/Data/Projects/San Jose Transit/google_transit/db/vta_gtfs.db";
}

@end
