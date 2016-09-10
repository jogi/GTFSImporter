//
//  main.m
//  GTFSImporter
//
//  Created by Vashishtha Jogi on 8/27/11.
//  Copyright 2011 Vashishtha Jogi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVImporter.h"
#import "Util.h"

int main (int argc, const char * argv[])
{
    NSLog(@"Originally built by Vashishtha Jogi -> https://github.com/jvashishtha.");
    NSLog(@"Modified by Connect Think LLC -> www.connectthink.com ");
    NSLog(@"Source available at https://github.com/ConnectThink/GTFSImporter");
    NSLog(@"=========================");
    
    // SET PATH OVERRIDES
    if (argc >= 2) {
        NSString *sourcePath = [NSString stringWithUTF8String:argv[1]];
        [Util setTransitFilesBasepath:sourcePath];
    }
    
    if (argc >= 3) {
        NSString *destinationPath = [NSString stringWithUTF8String:argv[2]];
        [Util setDatabasePath:destinationPath];
    }
    
    // IMPORT
    CSVImporter *importer = [[CSVImporter alloc] init];
    
    NSLog(@"Importing Agency...");
    [importer addAgency];
    
    
    NSLog(@"Importing Fare Attributes...");
    [importer addFareAttributes];
    
    
    NSLog(@"Importing Fare Rules...");
    [importer addFareRules];
    
    
    NSLog(@"Importing Calendar...");
    [importer addCalendar];
    
    
    NSLog(@"Importing Calendar Dates...");
    [importer addCalendarDate];
    
    
    NSLog(@"Importing Routes...");
    [importer addRoute];
    
    
    NSLog(@"Importing Stops...");
    [importer addStop];
    

    NSLog(@"Importing Trips...");
    [importer addTrip];
    
    
    NSLog(@"Importing Shapes...");
    [importer addShape];
    
    
    NSLog(@"Importing StopTime...");
    [importer addStopTime];
    
    //Comment this out if you dont want to apply any transformations
    //NSLog(@"Sanitizing data...");
    //[importer sanitizeData];
	
    NSLog(@"Vacumming...");
    [importer vacuum];
    
    
    NSLog(@"Reindexing...");
    [importer reindex];
    
    
    //For convinience. This will add and extra column routes which will contain comma seperated route numbers passing through this stop
    NSLog(@"Adding routes to stops...");
    [importer addStopRoutes];
    
    NSLog(@"Interpolating stop times");
    [importer addInterpolatedStopTime];
    
    NSLog(@"Vacumming...");
    [importer vacuum];
    
    NSLog(@"Reindexing...");
    [importer reindex];
    
    NSLog(@"Import complete!");
    
    return 0;
}
