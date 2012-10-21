## What is it ?

It's an iOS SQLite 3 Connect API Library to make database with app.

## How To Get Started

To Imports "Database.h".

``` objective-c
//A sample of making a table.
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
```

