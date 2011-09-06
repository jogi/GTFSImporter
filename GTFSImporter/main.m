//
//  main.m
//  GTFSImporter
//
//  Created by Vashishtha Jogi on 8/27/11.
//  Copyright 2011 Adobe Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVImporter.h"

int main (int argc, const char * argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
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
    
    NSLog(@"Sanitizing data...");
    [importer sanitizeData];
    
    NSLog(@"Vacumming...");
    [importer vacuum];
    
    NSLog(@"Reindexing...");
    [importer reindex];
     
    
    NSLog(@"Adding routes to stops...");
    [importer addStopRoutes];
    
    NSLog(@"Vacumming...");
    [importer vacuum];
    
    NSLog(@"Reindexing...");
    [importer reindex];
    
    NSLog(@"Import complete!");
    
    
    [importer release];

    [pool drain];
    return 0;
}

