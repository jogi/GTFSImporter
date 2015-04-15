//
//  main.m
//  GTFSImporter
//
//  Created by Vashishtha Jogi on 8/27/11.
//  Copyright 2011 Vashishtha Jogi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVImporter.h"

int main (int argc, const char * argv[])
{
    
    CSVImporter *importer = [[CSVImporter alloc] init];
    
    NSLog(@"Importing Agency...");
    [importer addAgency];
    
    
    NSLog(@"Importing Fare Attributes...");
    [importer addFareAttributes];
    
    
    NSLog(@"Importing Fare Rules...");
    [importer addFareRules];
    
    
    NSLog(@"Importing Calendar...");
    [importer addCalendar];
    
    
    NSLog(@"Importing Routes...");
    [importer addRoute];
    
    
    NSLog(@"Importing Stops...");
    [importer addStop];
    
    
    NSLog(@"Importing Trips...");
    [importer addTrip];
    
    
    NSLog(@"Importing StopTime...");
    [importer addStopTime];
    
    //Comment this out if you dont want to apply any transformations
//    NSLog(@"Sanitizing data...");
//    [importer sanitizeData];
	
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

