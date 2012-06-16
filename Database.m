//
//  Database.m
//
//  Version 1.1
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2012/06/01.
//  Copyright 2011 Kuo-Ming Lin. All rights reserved.
//
#import "Database.h"

@interface Database (Private)

-(NSString *)_trimString:(NSString *)_string;
-(BOOL)_stringIsEmpty:(NSString *)_checkString;

@end

@implementation Database (Private)

-(BOOL)_stringIsEmpty:(NSString *)_checkString{
    NSString *_string = [self _trimString:[NSString stringWithFormat:@"%@", _checkString]];
    return ( [_string isEqualToString:@""] || [_string length] < 1 ) ? YES : NO;
}

-(NSString *)_trimString:(NSString *)_string{
    return [_string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end


@implementation Database

@synthesize isConnecting;

- (id)init
{
    self = [super init];
    if (self) {
        self.isConnecting = ( [self connectWithDatabase] == SQLITE_OK ) ? YES : NO;
    }
    return self;
}

//取得資料庫檔案存放完整路徑名稱
-(NSString *)getDatabaseSavedPath{
    //取得根目錄路徑集合陣列
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //取得根目錄
    NSString *documentsDirectory = [paths objectAtIndex:0];
    //結合 DB 檔案全名
    NSString *fullDbName = [NSString stringWithFormat:@"%@%@", DBNAME, DBEXT];
    //組合成資料庫檔案完整路徑回傳
    return [documentsDirectory stringByAppendingPathComponent:fullDbName];    
}

//檢查資料庫檔案是否存在
-(BOOL)databaseExists{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *databasePath     = [self getDatabaseSavedPath];
    return [fileManager fileExistsAtPath:databasePath];    
}

//準備資料庫
-(void)readyWithDatabase{
    if( ![self databaseExists] ){
        //複製預備資料庫
        [self copyWithoutDatabase];
    }    
}

//當資料庫不存在時複製預備資料庫 
-(void)copyWithoutDatabase{
    NSError *error;
    //啟動檔案管理員
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbPath           = [self getDatabaseSavedPath];
    //檢查資料庫是否存在
    BOOL success               = [fileManager fileExistsAtPath:dbPath]; 
	//資料庫檔案不存在
    if( !success ) {
		//取出存在 APP 裡的預備 DB ( 表單欄位都建好的 DB )
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] 
                                   stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", DBNAME, DBEXT]];
        //將預備 DB 複製到原先設定的 DB 路徑
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        //NSLog(@"已複製預備 DB 到 : %@ \n", dbPath);
		//複製失敗
        if (!success){ 
            NSAssert1(0, @"複製預備 DB 失敗，Error : %@ \n", [error localizedDescription]);
        }
    }else{
        //資料庫存在
        //NSLog(@"找到原先的 DB 在 : %@ \n", dbPath);
    }
}

//連結資料庫 : DB 不存在時，會重建一個
-(int)connectWithDatabase{
    NSString *databasePath = [self getDatabaseSavedPath];
    //如果已在 init 初始時開啟資料庫連線 : 則直接回傳連線成功
    if( self.isConnecting == YES ){
        return SQLITE_OK;
    }
    
    //連接資料庫並回傳狀態( INT 型態 ) : sqlite3_open 會同時新建一個資料庫
    int connectStatus      = sqlite3_open([databasePath UTF8String], &database);
    //資料庫開啟失敗
    if( connectStatus != SQLITE_OK ){
        //關閉 SQLite
        [self closeWithDatabase];
    }else{
        //NSLog(@"資料庫連線中 \n");
    }
    
    return connectStatus;
}

//關閉資料庫
-(void)closeWithDatabase{
    sqlite3_close(database);
    self.isConnecting = NO;
}

//刪除資料庫
-(void)dropWithDatabase{
    //先檢查 DB 檔案是否存在
    if( [self databaseExists] ){
        //宣告檔案管理員
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //刪除檔案
        [fileManager removeItemAtPath:[self getDatabaseSavedPath] error:nil];
    }else{
        //NSLog(@"無法刪除不存在的 Database \n");
    }
    
    self.isConnecting = NO;
}

/*
 * # 查詢 Sample : 
 *   1). sqlString = @"SELECT * FROM t_test WHERE score > 0";
 *   2). sqlString = @
 *   
 *   [self execSelect:sql resultColumns:4];
 * 
 * # 回傳值 : 以欄位名為 Key, 欄位值為 Value
 *
 */
//查詢 : 回傳的陣列裡，第二次陣列為 Dictionary :: KEY / 欄位名, Value / 資料 :: 參數 :: SQL 語句 :: 設定查詢結果要取得表單裡哪幾個欄位的值
-(NSMutableArray *)execSelect:(NSString *)_sqlString 
                resultColumns:(int)_cols{
    //查詢的結果陣列
	NSMutableArray *dataArray = [[[NSMutableArray alloc] init] autorelease];
    //開啟資料庫連線 : 成功
    if( [self connectWithDatabase] == SQLITE_OK ){
        //SQL 查詢結果存在 sqlite3_stmt 類型裡( $Result )
        sqlite3_stmt *statement = nil;
        //進行查詢
        if ( sqlite3_prepare_v2(database, [_sqlString UTF8String], -1, &statement, NULL) == SQLITE_OK ) {
            //開始取出資料 : 使用 sqlite3_step( *sqlite3_stmt ) 一次取一筆
            while (sqlite3_step(statement) == SQLITE_ROW) {
                //存放一筆記錄 : 使用 KEY / VALUE 方式儲存
				NSMutableDictionary *rowsArray = [[NSMutableDictionary alloc] init];
				//_cols 限定取出表單裡的哪幾個欄位的值
				for( int i=0; i<_cols; i++ ){
                    //目前的 SQL 欄位名稱 :: KEY
                    NSString *rowName  = [NSString stringWithFormat:@"%s", sqlite3_column_name(statement, i)];
                    NSString *rowValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)];                             
                    //存入字典陣列 : 欄位值 / 欄位名
                    [rowsArray setValue:rowValue forKey:rowName]; 
				}
                //存入回傳陣列
				[dataArray addObject:rowsArray];
                
				[rowsArray release];
            }//end while
        }else {
			NSLog(@"Error: failed to prepare");
			return NO;
		}//end if
        //釋放記憶體
        sqlite3_finalize(statement);    
    
    }else{
        //連線失敗
        //NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));        
    }
    
    [self closeWithDatabase];
    
	return dataArray;    
}
/*
   
 */
/*
 * # Sample : 
 *   //新增
 *   NSArray *paramArray = [NSArray arrayWithObjects:@"Miles", @"28", @"69", nil];
 *   NSString *sql       = [NSString stringWithString:@"INSERT INTO t_test (name, age, score) VALUES (?, ?, ?)"];
 *    
 *   //刪除
 *   NSArray *paramArray = [NSArray arrayWithObjects:@"2", nil];
 *   NSString *sql       = [NSString stringWithString:@"DELETE FROM t_test WHERE id=?"];
 *    
 *   //修改
 *   NSArray *paramArray = [NSArray arrayWithObjects:@"Miles", @"30", @"2", nil];
 *   NSString *sql       = [NSString stringWithString:@"UPDATE t_test SET name=?, age=? WHERE id=?"];
 *
 *   [self execQuery:sql sqlParamArray:paramArray];
 *
 * # 注意事項 : 
 *    用 SQLite 來存放中文或其他非英數字串 , 使用 sqlite3_column_text() 取出後是亂碼，解決方法：
 *    取得字串後( 字串不可為空值 )，要用 stringWithUTF8String 的方法轉換成 NSString， 
 *    NSString *tmp = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, iCol)];  
*/
//新增 / 刪除 / 修改
-(BOOL)execQuery:(NSString *)_sqlString 
   sqlParamArray:(NSArray *)_params{
	
    if ( [self connectWithDatabase] == SQLITE_OK ) {
        //建立記錄要執行的 SQL 語句之物件
        sqlite3_stmt *statement = nil;
        
        //NSLog(@"UTF8String : %s\n", [_sqlString UTF8String]);
        
        int success = sqlite3_prepare_v2(database, [_sqlString UTF8String], -1, &statement, NULL);
        
		if (success != SQLITE_OK) {
			//NSLog(@"Error: execQuery 轉換成位元組碼失敗 : %s \n", [_sqlString UTF8String]);
			return NO;
		}
        
		//绑定参数
		NSInteger max = [_params count];
		for (int i=0; i<max; i++) {
			NSString *temp = [_params objectAtIndex:i];
            //如為空字串
            if( [self _stringIsEmpty:temp] ){
                //將字串設定預設值後再寫入 DB
                temp = [NSString stringWithString:DEFAULT_STRING];
            }
			sqlite3_bind_text(statement, i+1, [temp UTF8String], -1, SQLITE_TRANSIENT);
		}
        
        //執行經由 sqlite3_prepare_v2() 方法編成位元組碼的 SQL 語句
		success = sqlite3_step(statement);
        
        //釋放 statement : 之後關閉資料庫
        sqlite3_finalize(statement);
        //關閉資料庫
		[self closeWithDatabase];
        
        if (success == SQLITE_ERROR) {
			return NO;
		}
    }
	return YES;    
    
}

/*
 * # Sample (使用一般查詢語句進行資料筆數的計算) : 
 *   1). _sqlString = @"SELECT * FROM journal";
 *   2). _sqlString = @"SELECT * FROM journal WHERE journal_title LIKE '%Trips%'";
 *   3). _sqlString = @"SELECT * FROm journal WHERE journal_id IN ( SELECT journal_id FROM matchs LIMIT 0, 10 )";
 *
 *   [self getRowsNumbersOfExecSQL:_sqlString];
 */
//取得指定查詢的 SQL 語句資料總筆數
-(int)getRowsNumbersOfExecSQL:(NSString *)_sqlString{
    NSMutableArray *dataArray = [self execSelect:_sqlString resultColumns:1];
    int dataCount = [dataArray count];
    return ( dataCount > 0 ) ? dataCount : 0;   
}

/*
 * # Sample (使用 Count(*) 函式進行資料筆數的計算) : 
 *   1). _tableName = @"journal";
 *   2). _tableName = @"journal WHERE journal_id > 10";
 *   3). _tableName = @"journal WHERE journal_id IN ( SELECT journal_id FROM matchs LIMIT 0, 10 )";
 *
 *   [self getRowsNumbersOfExecTable:_tableName];
 */
//取得指定資料表的資料總筆數
-(int)getRowsNumbersOfExecTable:(NSString *)_tableName{
    NSString *_sqlString = [NSString stringWithFormat:@"SELECT count(*) AS rows_number FROM %@", _tableName];
    NSMutableArray *dataArray = [self execSelect:_sqlString resultColumns:1];
    return ( [dataArray count] > 0 ) ? [[[dataArray objectAtIndex:0] objectForKey:@"rows_number"] intValue] : 0;
}

/*
 * # 範例 ( 回傳 Dictionary ): 
 *   1). 傳入總筆數 + 現在的分頁數 + ( 預設取 10 筆 ) :
 *      NSDictionary *pageDicts = [self calculatePagesWithTotal:100 
 *                                                   andNowPage:1 
 *                                                andLimitStart:0 
 *                                                  andLimitEnd:0];
 *
 *   2). 傳入總筆數 + 現在分頁數 + 取出 8 筆 : 
 *
 *      NSDictionary *pageDicts = [self calculatePagesWithTotal:100 
 *                                                   andNowPage:1 
 *                                                andLimitStart:0 
 *                                                  andLimitEnd:8];
 *
 *   3). 傳入總筆數 + 現在分頁數 + 從第 10 筆開始取 + 取出 8 筆: 
 *
 *      NSDictionary *pageDicts = [self calculatePagesWithTotal:100 
 *                                                   andNowPage:1 
 *                                                andLimitStart:10 
 *                                                  andLimitEnd:8];
 *
 * # 參數 : 
 *   _totalPages : 資料總筆數
 *   _nowPage    : 現在分頁數 ( INT )
 *   _start      : SQL 資料開始筆數 ( 從第幾筆開始取, LIMIT_START )
 *   _end        : SQL 資料結束筆數 ( 要取出幾筆, LIMIT_END )
 *
 * # 使用計算後的分頁 Sample : 
 *
 *   。第一頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"first"];
 *   。上一頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"first"];
 *   。下一頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"next"];
 *   。最後頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"last"];
 *   。跳轉頁 : 
 *      NSDictionary *jumpDicts = [pageDicts objectForKey:@"jumps"];
 *      foreach( NSString *jumpPage in jumpDicts ){
 *        //第 jumpPage 頁 : @"www.test.com/index.php?ls=%@", [jumpDicts objectForKey:jumpPage];
 *      }
 *   。現在頁 : [pageDicts objectForKey:@"nowPage"];
 *
 */
//直接計算分頁 : 總頁數 / 現在頁數 / Limit Start / Limit End
-(NSDictionary *)calculatePagesWithTotal:(int)_totalPages 
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end{
    
    //到第幾筆結束 ?
    int limitEnd    = ( _end < 1 ) ? DEFAULT_LIMIT_END : _end;
    //當前頁數
    int currentPage = ( _nowPage - 1 > 0 ) ? _nowPage - 1 : 0;
    //從第幾筆開始 ?
    int limitStart  = ( _start > 0 ) ? _start : currentPage * limitEnd;
    //總共有幾筆
    int total       = _totalPages;
    //第一頁
    int first       = 0;
    //下一頁
    int next        = ( (limitStart + limitEnd) >= total ) ? limitStart : limitStart + limitEnd;
    //上一頁
    int previous    = ( (limitStart - limitEnd) >= 0 ) ? limitStart - limitEnd : 0;
    //最後一頁
    int last        = ( (floor( (total - 1) / limitEnd ) * limitEnd) >= 0 ) ? floor( (total - 1) / limitEnd ) * limitEnd : 0;
    //現在頁數
    int nowPage     = ceil( limitStart / limitEnd ) + 1;
    //總頁數
    int totalPages  = ceil( total / limitEnd );
    //下一頁的頁數
    int nextPage    = ( nowPage >= totalPages )? totalPages : nowPage + 1;
    //是否還有下一頁 ?
    NSString *hasNext = ( nowPage < totalPages )? @"YES" : @"NO";
    //跳頁 - 陣列型態 : jumpDicts[第幾頁] = 從第幾筆開始
    NSMutableDictionary *jumpDicts = [[NSMutableDictionary alloc] init];
    for( int i=0; i<totalPages; i++ ){
        int jumpStart = ( i == 0 ) ? 0 : i * limitEnd;
        [jumpDicts setValue:[NSString stringWithFormat:@"%i", jumpStart] 
                     forKey:[NSString stringWithFormat:@"%i", (i + 1)]];
    }
    //現在是呈現到第幾筆結束 ?
    int currentEnd  = ( nowPage * limitEnd > total ) ? total : nowPage * limitEnd;
    //現在是從第幾筆開始 ?
    int startNumber = ( limitStart > 0 ) ? limitStart : 0;
    //製作回傳字典陣列
    NSDictionary *pageDicts = [NSDictionary dictionaryWithObjectsAndKeys:
                               //第一頁筆數
                               [NSString stringWithFormat:@"%i", first],       @"first",
                               //下一頁筆數
                               [NSString stringWithFormat:@"%i", next],        @"next", 
                               //上一頁筆數
                               [NSString stringWithFormat:@"%i", previous],    @"previous",
                               //最後一頁筆數
                               [NSString stringWithFormat:@"%i", last],        @"last", 
                               //開始筆數
                               [NSString stringWithFormat:@"%i", startNumber], @"start", 
                               //結束筆數
                               [NSString stringWithFormat:@"%i", limitEnd],    @"end", 
                               //本次是取到第幾筆資料而結束的
                               [NSString stringWithFormat:@"%i", currentEnd],  @"currentEnd", 
                               //現在的分頁數
                               [NSString stringWithFormat:@"%i", nowPage],     @"nowPage", 
                               //下一個分頁數
                               [NSString stringWithFormat:@"%i", nextPage],    @"nextPage", 
                               //總分頁數
                               [NSString stringWithFormat:@"%i", totalPages],  @"totalPages", 
                               //是否還有下一頁 ( STRING : YES : NO )
                               hasNext,   @"hasNext", 
                               //跳頁陣列 : [分頁數] = LIMIT_START
                               jumpDicts, @"jumps", 
                               nil];
    [jumpDicts release];
    return pageDicts;
}

/*
 * #使用範例同上述 calculatePagesWithTotal:::: 函式，唯一不同處 _tableName 的寫法可為: 
 *
 *   1). 直接傳入資料表名稱 : @"journal";
 *
 *   2). 加入 WHERE 條件式或子查詢 ( 其他緊跟在 FROM 後的 SQL 寫法都行 ) : @"journal WHERE journal_id < 10";
 *
 */
//指定計算資料表分頁 : 總頁數 / 現在頁數 / Limit Start / Limit End
-(NSDictionary *)calculatePagesWithTable:(NSString *)_tableName 
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end{
    
    int total = [self getRowsNumbersOfExecTable:_tableName];
    return [self calculatePagesWithTotal:total 
                              andNowPage:_nowPage 
                           andLimitStart:_start 
                             andLimitEnd:_end];
}

//新建資料表 : 資料表名稱 :: 欄位與參數
-(void)createTablesWithName:(NSString *)_tableName 
                  andParams:(NSDictionary *)_paramsArray{
    
    char *createErrors;
    
    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(", _tableName];
    
    //取出欄位名( key ) 與欄位參數( value )
    int i = 0;
    for( NSString *sqlRowName in _paramsArray ){
        if( i < 1 ){
            sqlString = [sqlString stringByAppendingFormat:@"%@ %@", sqlRowName, [_paramsArray objectForKey:sqlRowName]];
        }else{
            sqlString = [sqlString stringByAppendingFormat:@", %@ %@", sqlRowName, [_paramsArray objectForKey:sqlRowName]];
        }
        i++;
    }
    
    sqlString = [sqlString stringByAppendingString:@" );"];
    
    //NSLog(@"createTables sqlString : %@ \n", sqlString);
    
    //連結資料庫成功
    if( [self connectWithDatabase] == SQLITE_OK ){
        //執行 SQL 語法 : 如果執行失敗
        if( sqlite3_exec(database, [sqlString UTF8String], NULL, NULL, &createErrors) != SQLITE_OK ){
            //關閉 DB
            [self closeWithDatabase];
            sqlite3_free(createErrors);
        }else{
            //NSLog(@"建立 %@ 資料表成功\n", _tableName);
        }//endif
    }else{
    
        //NSLog(@"連結資料庫失敗 \n");
        
    }

}

//刪除資料表
-(void)dropTableWithName:(NSString *)_tableName{
    char *dropErrors;
    NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", DBNAME, _tableName];
    //連結資料庫成功
    if( [self connectWithDatabase] == SQLITE_OK ){
        if( sqlite3_exec(database, [sqlString UTF8String], NULL, NULL, &dropErrors) != SQLITE_OK ){
            [self closeWithDatabase];
            sqlite3_free(dropErrors);
        }
    }
}

//重新命名資料表名稱 : 舊資料表名稱 :: 新資料表名稱
-(void)alterTableWithName:(NSString *)_tableName 
                 renameTo:(NSString *)_tableRename{
    char *renameErrors;
    NSString *renameSql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@", _tableName, _tableRename];
    //連結資料庫成功
    if( [self connectWithDatabase] == SQLITE_OK ){
        if( sqlite3_exec(database, [renameSql UTF8String], NULL, NULL, &renameErrors) != SQLITE_OK ){
            [self closeWithDatabase];
            sqlite3_free(renameErrors);
        }
    }
}

//增加資料表欄位 : 資料表名稱 :: 欄位與參數
-(void)alterTableWithName:(NSString *)_tableName 
                addColumns:(NSDictionary *)_paramsArray{
    //連結資料庫成功
    if( [self connectWithDatabase] == SQLITE_OK ){
        for( NSString *sqlRowName in _paramsArray ){
            NSString *alterSql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", 
                                  _tableName, 
                                  sqlRowName, 
                                  [_paramsArray objectForKey:sqlRowName]];
            //執行 SQL
            sqlite3_exec(database, [alterSql UTF8String], NULL, NULL, NULL);
        }
        //關閉連線
        [self closeWithDatabase];
    }
}

-(void)dealloc{
    //[database release];
    [super dealloc];
}

@end

