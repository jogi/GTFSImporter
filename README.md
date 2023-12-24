### Welcome!
Import GTFS csv files to a sqlite database

### How to use it?
Modify the `Util.m` file to reflect the correct file paths. See the comments in the file for instructions on how to change the paths.

Thats it! Run the project.

***

### What does it do to the data?
* It first imports all the data to a sqlite db.
* Then it applies any transformations if there are any that are needed. In my case --**Santa Clara Valley Transportation Authority**-- the data had several trips which where no longer valid because the date for them had already passed! So I added the queries to sanitize the data appropriately.
* Then it will add a column routes to stops table which will contain all the route number (to be specific route ids) passing through the stop in a comma seperated format.
* This also adds time interpolation for all the stops which originally din't have times. All the stops will have arrival times filled up by default based on the the stop times already there. An extra column `is_timepoint` is added to the stop_times table which allows you to distinguish between original times and interpolated times. 1 is original and 0 is interpolated stop.
