//
//  Database.h
//
//  Version 1.1
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2012/06/01.
//  Copyright 2011 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>

#define DBNAME              @"sample_db"
#define DBEXT               @".sqlite3"
#define DEFAULT_STRING      @"NO"
#define DEFAULT_LIMIT_START 0
#define DEFAULT_LIMIT_END   10

@interface Database : NSObject{

@protected
    sqlite3 *database;
    
}

@property (nonatomic, assign) BOOL isConnecting;

//取得資料庫檔案存放完整路徑名稱
-(NSString *)getDatabaseSavedPath;
//檢查資料庫檔案是否存在
-(BOOL)databaseExists;
//準備資料庫
-(void)readyWithDatabase;
//當資料庫不存在時複製預備資料庫
-(void)copyWithoutDatabase;
//連結資料庫
-(int)connectWithDatabase;
//關閉資料庫
-(void)closeWithDatabase;
//刪除資料庫
-(void)dropWithDatabase;
//查詢 : 回傳的陣列裡，第二次陣列為 Dictionary :: KEY / 欄位名, Value / 資料 :: 參數 :: SQL 語句 :: 設定查詢結果要取得表單裡哪幾個欄位的值
-(NSMutableArray *)execSelect:(NSString *)_sqlString 
                resultColumns:(int)_cols;
//新增 / 刪除 / 修改
-(BOOL)execQuery:(NSString *)_sqlString 
   sqlParamArray:(NSArray *)_params;
//取得指定查詢的 SQL 語句資料總筆數
-(int)getRowsNumbersOfExecSQL:(NSString *)_sqlString;
//取得指定資料表的資料總筆數
-(int)getRowsNumbersOfExecTable:(NSString *)_tableName;
//直接計算分頁 : 總頁數 / 現在頁數 / Limit Start / Limit End
-(NSDictionary *)calculatePagesWithTotal:(int)_totalPages 
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end;
//指定資料表計算分頁 : 總頁數 / 現在頁數 / Limit Start / Limit End
-(NSDictionary *)calculatePagesWithTable:(NSString *)_tableName 
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end;
//新建資料表 : 資料表名稱 :: 欄位與參數
-(void)createTablesWithName:(NSString *)_tableName 
                  andParams:(NSDictionary *)_paramsArray;
//刪除資料表
-(void)dropTableWithName:(NSString *)_tableName;
//重新命名資料表名稱 : 舊資料表名稱 :: 新資料表名稱
-(void)alterTableWithName:(NSString *)_tableName 
              renameTo:(NSString *)_tableRename;
//增加資料表欄位 : 資料表名稱 :: 欄位與參數
-(void)alterTableWithName:(NSString *)_tableName 
                addColumns:(NSDictionary *)_paramsArray;

@end
