ios-sqlite-connect
====================

iOS SQLite Connect API Library, 

It used SQLite 3 of iOS to make database in apps.

#A sample of making tables: 

--#import "Database.h"
-(void)createTables{
	Database *Db = [[Database alloc] init];
	if( [Db databaseExists] ){
		[Db connectWithDatabase];
		NSDictionary *tableParamsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         @"INTEGER PRIMARY KEY AUTOINCREMENT", @"journal_id",
                                         @"TEXT DEFAULT 'NO'", @"journal_title",
                                         @"TEXT DEFAULT 'NO'", @"journal_desc",
                                         @"DATETIME DEFAULT CURRENT_TIMESTAMP", @"journal_date",
                                         @"VARCHAR DEFAULT 'Life'", @"journal_type",
                                         nil];
    	[Db createTablesWithName:@"journal" andParams:tableParamsDict];        
    }
    [Db release];
}

