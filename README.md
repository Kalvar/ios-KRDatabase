## What is it ?

It's an iOS SQLite 3 Connect API Library to make database with app, that you need to add a framework of Apple named "libsqlite3.0.dylib" first.

## How To Get Started

``` objective-c
#import "KRDatabase.h".
//Create a Table
-(void)createTable
{
	KRDatabase *_krDatabase = [[KRDatabase alloc] init];
	if( [_krDatabase databaseExists] )
    {
		NSDictionary *tableParamsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         @"INTEGER PRIMARY KEY AUTOINCREMENT", @"journal_id",
                                         @"TEXT DEFAULT 'NO'", @"journal_title",
                                         @"TEXT DEFAULT 'NO'", @"journal_desc",
                                         @"DATETIME DEFAULT CURRENT_TIMESTAMP", @"journal_date",
                                         @"VARCHAR DEFAULT 'Life'", @"journal_type",
                                         @"INT(10)", @"journal_code",
                                         nil];
    	[_krDatabase createTablesWithName:@"journal" andParams:tableParamsDict];        
    }
}

-(void)othersSample
{
    //SELECT
    NSMutableArray *results = [[KRDatabase sharedManager] execSelect:@"SELECT * FROM sample_table WHERE sample_id = 1"];
    for( NSDictionary *_eachRows in results )
    {
        NSString *_row1 = [_eachRows objectForKey:@"sample_row1"];
        //...
    }
    //UPDATE
    [[KRDatabase sharedManager] execQuery:@"UPDATE sample_table SET sample_name = 'WOW' WHERE sample_id = 1"];
    //DELETE
    [[KRDatabase sharedManager] execQuery:@"DELETE FROM sample_table WHERE sample_id = 1"];
    //Check out the Table is exist
    if( ![[KRDatabase sharedManager] tableExistsWithName:@"myTable"] )
    {
        //Do Create myTable
    }
}
```

## Version

V1.3

## LICENSE

MIT
