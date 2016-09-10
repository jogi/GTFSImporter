//
//  AppDelegate.m
//  GTFSImporteriOS
//
//  Created by Aaron Jubbal on 9/10/16.
//  Copyright © 2016 Aaron Jubbal. All rights reserved.
//

#import "AppDelegate.h"
#import "ZipArchive.h"
#import "CSVImporter.h"
#import "Util.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"GTFS Caltrain Devs" ofType:@"zip"];
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSError *error = nil;
    NSString *destinationPath = libraryDirectory;
    [[NSFileManager defaultManager] createDirectoryAtPath:destinationPath
                              withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"error occured while creating directory! %@", error);
    }
    [SSZipArchive unzipFileAtPath:sourcePath toDestination:destinationPath];
    
    NSString *gtfsSourcePath = [destinationPath stringByAppendingPathComponent:@"GTFS Caltrain Devs"];
    [Util setTransitFilesBasepath:gtfsSourcePath];
    [Util setDatabasePath:[gtfsSourcePath stringByAppendingPathComponent:@"gtfs.db"]];
    
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
    
    NSLog(@"database written to: %@", gtfsSourcePath);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
