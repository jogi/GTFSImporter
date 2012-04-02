### Welcome!
Import GTFS csv files to a sqlite database

### How to use it?
Modify the `Util.m` file to reflect the correct file paths. See the comments in the file for instructions on how to change the paths.

Thats it! Run the project and you should be fine.

***

### What does it do to the data??
* It first imports all the data to a sqlite db.
* Then it applies any transformations if there are any that are needed. In my case --**Santa Clara Valley Transportation Authority**-- the data had several trips which where no longer valid because the date for them had already passed! So i added the queries to sanitize the data appropriately.
* Then it will add a column routes to stops table which will contain all the route number (to be specific route ids) passing through the stop in a comma seperated format. I wanted this data! So I made this :-)
* Then it reindexes the data and performs the vaccuum command.
* One very important feature that I have added is time interpolation for all the stops which originally din't have times. Yups. Time interpolation. All the stops will have arrival times filled up by default based on the the stop times already there. An extra column `is_timepoint` is added to the stop_times table which allows you to distinguish between original times and interpolated times. 1 is original and 0 is interpolated stop.

### One important NOTE
Dont remove the indexes that I have added. They are very much needed for fast query performance. Believe me.

### Authors and Contributors
Vashishtha Jogi (@jvashishtha).

### Support or Contact
Having trouble with **GTFSImporter**? Create an issue or email me directly at vashishthajogi@gmail.com and I will help you sort it out.