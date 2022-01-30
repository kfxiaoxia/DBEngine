//
//  ViewController.swift
//  DBEngine
//
//  Created by zhifou on 1/30/22.
//
import Foundation
import FMDB

class DBEngine: NSObject {
    
    static let shared: DBEngine = DBEngine()
    
    let databaseFileName = "database.sqlite"
     
    var path: String!

    var dbQueue: FMDatabaseQueue!

    
    override init() {
        super.init()
        let documentsDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        path = documentsDirectory.appending("/\(databaseFileName)")
        createDatabase()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    /// 创建数据库
    func createDatabase()  {
        dbQueue = FMDatabaseQueue.init(path: path)
        dbQueue.inDatabase({ db in
            if db.open() {
                print("数据库创建成功")
            } else {
                print("数据库创建失败")
            }
        })
    }
    
    
    /// 创建表
    /// - Parameters:
    ///   - tablename: 表的名字
    ///   - columns: 表的列
    ///   - resultHandler: 结果: 成功 => (true, nil) ; 失败 => (false, error)
    func createTable(_ tablename: String, columns:[SQLiteColumn], resultHandler:((Bool, SQLError?)->())?) {
        // 1. 校验
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            print("tablename is empty");
            resultHandler?(false, SQLError.unexpected(msg: "tablename is empty"))
            return
        }
        if columns.isEmpty {
            resultHandler?(false, SQLError.unexpected(msg: "columns is empty"))
            return
        }
        
        var columns_n = columns.filter { col in
            return col.name.trimmingCharacters(in: .whitespaces).isEmpty == false
        }
        ///2.创建表
        ///2.1 用户如果没有传 create_time update_time id 则添加
        ///2.2 创建表
        
        let create_time = columns.filter({ col in
            return col.name == "create_time"
        })
        
        if create_time.isEmpty {
            columns_n.append(SQLiteColumn.init(name: "create_time", type: .TIMESTAMP))
        }
        
        let update_time =  columns.filter({ col in
            return col.name == "update_time"
        })
        
        if update_time.isEmpty {
            columns_n.append(SQLiteColumn.init(name: "update_time", type: .TIMESTAMP))
        }
        
        let id =  columns.filter({ col in
            return col.name == "id"
        })
        
        var auto_increase = false
        if id.isEmpty {
            columns_n.insert(SQLiteColumn.init(name: "id", type: .INTEGER), at: 0)
            auto_increase = true
        }
        
        let sql_shell = "CREATE TABLE IF NOT EXISTS \(tablename) (%@);"
        
        var sql_cols: [String] = []
        
        var sql_uniques: [String] = []

        for item in columns_n {
            if item.name == "id" && auto_increase == true {
                let sql = "id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"
                sql_cols.append(sql)
            } else if item.name == "create_time" || item.name == "update_time" {
                let sql  = "\(item.name) timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP"
                sql_cols.append(sql)
            } else {
                let sql = "\(item.name) \(item.type.rawValue)"
                sql_cols.append(sql)
            }
            
            if item.isUnique {
                let sql = "UNIQUE (\(item.name))"
                sql_uniques.append(sql)
            }
        }
        
        if sql_uniques.isEmpty == false {
            sql_cols.append(contentsOf: sql_uniques)
        }
        
        let sql_cols_string = sql_cols.joined(separator: ",")
        print("sql_cols_string: \(sql_cols_string)")
        
        let sql_full = String(format: sql_shell, sql_cols_string)
        print("sql_full: \(sql_full)")
        
        dbQueue.inDatabase { db in
            guard db.open() else {
                resultHandler?(false, SQLError.unopen(msg: "Failed to open database"))
                return
            }
            if !db.executeStatements(sql_full) {
                resultHandler?(false, SQLError.unexpected(msg: db.lastErrorMessage()))
            } else {
                resultHandler?(true, nil)
            }
            
            db.close()
        }
        
    }
    
    
    /// 增加字段
    /// - Parameters:
    ///   - tablename: 表的名字
    ///   - columns: 列的信息
    ///   - resultHandler: 结果: 成功 => (true, nil) ; 失败 => (false, error)
    func addColumn(_ tablename: String, columns: [SQLiteColumn], resultHandler:((Bool, SQLError?)->())?) {
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            print("tablename is empty");
            resultHandler?(false, SQLError.unexpected(msg: "tablename is empty"))
            return
        }
        if columns.isEmpty {
            resultHandler?(false, SQLError.unexpected(msg: "columns is empty"))
            return
        }
        
        let columns_n = columns.filter { col in
            return col.name.trimmingCharacters(in: .whitespaces).isEmpty == false
        }
        

        var add_cols: [String] = []
        for col in columns_n {
            let col = "ALTER TABLE tabel_name_example ADD \(col.name) \(col.type.rawValue)"
            add_cols.append(col)
        }
        
        let sql_full = add_cols.joined(separator: ";")
        
        
        dbQueue.inDatabase { db in
            guard db.open() else {
                resultHandler?(false, SQLError.unopen(msg: "Failed to open database"))
                return
            }
            if !db.executeStatements(sql_full) {
                resultHandler?(false, SQLError.unexpected(msg: db.lastErrorMessage()))
            } else {
                resultHandler?(true, nil)
            }
            
            db.close()
        }
        
    }
    
    
    /// 删除字段
    /// - Parameters:
    ///   - tablename: 表的名字
    ///   - columns: 列的信息
    ///   - resultHandler: 结果: 成功 => (true, nil) ; 失败 => (false, error)
    func dropColumn(_ tablename: String, columns: [String], resultHandler:((Bool, SQLError?)->())?) {
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            print("tablename is empty");
            resultHandler?(false, SQLError.unexpected(msg: "tablename is empty"))
            return
        }
        if columns.isEmpty {
            resultHandler?(false, SQLError.unexpected(msg: "columns is empty"))
            return
        }
        
        let sql = "ALTER TABLE \(tablename) DROP COLUMN"
        let cols = columns.joined(separator: ",")
        let sql_full = "\(sql) \(cols)"
        dbQueue.inDatabase { db in
            guard db.open() else {
                resultHandler?(false, SQLError.unopen(msg: "Failed to open database"))
                return
            }
            if !db.executeStatements(sql_full) {
                resultHandler?(false, SQLError.unexpected(msg: db.lastErrorMessage()))
            } else {
                resultHandler?(true, nil)
            }
            
            db.close()
        }
    }
    
    
    /// 更新表的内容；内容已存在则修改；没有则插入
    /// - Parameters:
    ///   - tablename: 表的名字
    ///   - pars: 内容 [字段名：值]
    ///   - resultHandler: 结果: 成功 => (true, nil) ; 失败 => (false, error)
    func update(_ tablename: String, pars:[String: Any], resultHandler: ((Bool, SQLError?)->())?) {
        // 已存在 => 修改
        // 不存在 => 添加
        // 1. 校验
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            print("tablename is empty");
            resultHandler?(false, SQLError.unexpected(msg: "tablename is empty"))
            return
        }
        if pars.isEmpty {
            resultHandler?(false, SQLError.unexpected(msg: "pars is empty"))
            return
        }
        

        let sql_shell = "REPLACE INTO \(tablename) (%@) VALUES(%@);"
        
        var sql_cols: [String] = []
        var sql_cols_values: [Any] = []
        var sql_cols_values_placeholder: [String] = []
        
        for (key, value) in pars {
            sql_cols.append(key)
            sql_cols_values_placeholder.append("?")
            sql_cols_values.append(value)
        }
        
        let cols = sql_cols.joined(separator: ",")
        let values_placeholder = sql_cols_values_placeholder.joined(separator: ",")
        
        let sql_full = String(format: sql_shell, cols, values_placeholder)
        
        dbQueue.inDatabase { db in
            guard db.open() else {
                resultHandler?(false, SQLError.unopen(msg: "Failed to open database"))
                return
            }
            
            
            if !db.executeUpdate(sql_full, withArgumentsIn: sql_cols_values) {
                resultHandler?(false, SQLError.unexpected(msg: "error : \(db.lastErrorMessage())"))
            } else {
                resultHandler?(true, nil)
            }
            
            db.close()
        }
 
        
    }
    
    /// 事务
    /// - Parameters:
    ///   - tablename: 表的名字
    ///   - pars: 插入的内容
    ///   - resultHandler: 结果: 成功 => (true, nil, [data]) ; 失败 => (false, error, [])
    func updateWithTransaction( tablename: String, records: [[String: Any]], resultHandler: ((Bool, SQLError?)->())?) {
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            print("tablename is empty");
            resultHandler?(false, SQLError.unexpected(msg: "tablename is empty"))
            return
        }

        
        dbQueue.inDatabase { db in
            guard  db.open() else {
                resultHandler?(false, SQLError.unexpected(msg: db.lastErrorMessage()))
                return
            }
            db.beginTransaction()
            do {
                for item in records {
                    let sql_shell = "REPLACE INTO \(tablename) (%@) VALUES(%@);"
                    var sql_cols: [String] = []
                    var sql_cols_values: [Any] = []
                    var sql_cols_values_placeholder: [String] = []
                    
                    for (key, value) in item {
                        sql_cols.append(key)
                        sql_cols_values_placeholder.append("?")
                        sql_cols_values.append(value)
                    }
                    
                    let cols = sql_cols.joined(separator: ",")
                    let values_placeholder = sql_cols_values_placeholder.joined(separator: ",")
                    
                    let sql_full = String(format: sql_shell, cols, values_placeholder)
                    
                    let res =  db.executeUpdate(sql_full, withArgumentsIn: sql_cols_values)
                    if !res {
                        print(db.lastErrorMessage())
                        // 抛出错误
                        throw(SQLError.unexpected(msg: db.lastErrorMessage()))
                    }
                }
                db.commit()
                resultHandler?(true, nil)
            } catch  {
                print(error)
                // 出现错误回滚
                db.rollback()
                resultHandler?(false, SQLError.unexpected(msg: db.lastErrorMessage()))
            }
            
            db.close()
        }
    }
    
    
    /// 查询记录
    /// - Parameters:
    ///   - tablename: 表的名字
    ///   - conditions: 条件 [字段名：字段内容]
    ///   - resultHandler: 结果: 成功 => (true, nil, [data]) ; 失败 => (false, error, [])
    func query(_ tablename: String, conditions:[String: Any], resultHandler: ((Bool, SQLError?, [Any])->())?) {
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            print("tablename is empty");
            resultHandler?(false, SQLError.unexpected(msg: "tablename is empty"), [])
            return
        }
        
        let sql_shell = "SELECT * FROM \(tablename) WHERE "
        var sql_cons: [String] = []
        var sql_values:[Any] = []
        for (key, value) in conditions {
            let sql = "\(key)=?"
            sql_values.append(value)
            sql_cons.append(sql)
        }
        
        let sql_cons_str = sql_cons.joined(separator: " AND ")
        
        var sql_full = sql_shell + sql_cons_str + ";"
        
        /// 如果没有查询条件，查询所有数据
        if conditions.isEmpty {
            sql_full = "SELECT * FROM \(tablename);"
            sql_values = []
        }
        
        dbQueue.inDatabase { db in
            guard db.open() else {
                resultHandler?(false, SQLError.unopen(msg: "Failed to open database"),[])
                return
            }
            
            
            let sql_tab_cols = "SELECT name FROM pragma_table_info ('\(tablename)');"
            var cols: [String] = []
            do {
                let res =  try db.executeQuery(sql_tab_cols, values: [])
                while res.next() {
                    if let v = res.string(forColumnIndex: 0) {
                        cols.append(v)
                    }
                }
            } catch  {
                print(error)
                resultHandler?(false, SQLError.unexpected(msg: "no cols"), [])
            }
            
            
            
            do {
                let res = try db.executeQuery(sql_full, values: sql_values)
                var datas: [[String: Any]] = []

                while res.next() {
                    var list:[String: Any] = [:]
                    for key in cols {
                        let v = res.object(forColumn: key)
                        list[key] = v
                    }
                    datas.append(list)
                }
                resultHandler?(true, nil, datas)
                
            } catch  {
                resultHandler?(false, SQLError.unexpected(msg: "error : \(db.lastErrorMessage())"), [])
            }
            
            db.close()
        }
        
    }
    
    
    /// 删除表中的记录
    /// - Parameters:
    ///   - tablename: 表明
    ///   - conditions: 条件 [字段名： 值]
    ///   - resultHandler: 结果: 成功 => (true, nil) ; 失败 => (false, error)
    func dropRecords(_ tablename: String, conditions:[String: Any], resultHandler: ((Bool, SQLError?)->())?) {
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            print("tablename is empty");
            resultHandler?(false, SQLError.unexpected(msg: "tablename is empty"))
            return
        }
        if conditions.isEmpty {
            resultHandler?(false, SQLError.unexpected(msg: "conditions is empty"))
            return
        }
        
        let sql_shell = "DELETE FROM \(tablename) WHERE  "
        var sql_cons: [String] = []
        var sql_values:[Any] = []
        for (key, value) in conditions {
            let sql = "\(key)=?"
            sql_values.append(value)
            sql_cons.append(sql)
        }
        
        let sql_cons_str = sql_cons.joined(separator: " AND ")
        
        let sql_full = sql_shell + sql_cons_str + ";"
        
        dbQueue.inDatabase { db in
            guard db.open() else {
                resultHandler?(false, SQLError.unopen(msg: "Failed to open database"))
                return
            }
            
            
            if !db.executeUpdate(sql_full, withArgumentsIn: sql_values) {
                resultHandler?(false, SQLError.unexpected(msg: "\(db.lastErrorMessage())"))
            } else {
                resultHandler?(true, nil)
            }
            
            db.close()
        }
    }
    
    /// 删除表
    /// - Parameters:
    ///   - tablename: 表的名字
    ///   - resultHandler: 结果: 成功 => (true, nil) ; 失败 => (false, error)
    func dropTable(_ tablename: String, resultHandler: ((Bool, SQLError?)->())?) {
        if tablename.trimmingCharacters(in: .whitespaces).isEmpty {
            resultHandler?(false, SQLError.unexpected(msg: "tablename is isEmpty"))
            return
        }
        let sql = "DROP TABLE IF EXISTS \(tablename)"
        dbQueue.inDatabase { db in
            guard db.open() else {
                resultHandler?(false, SQLError.unopen(msg: ""))
                return
            }
            
            if !db.executeStatements(sql) {
                let e = SQLError.unexpected(msg: "DROP TABLE FAIL | sql: \(sql) | error: \(db.lastErrorMessage())")
                resultHandler?(false, e)
            } else {
                print("DROP TABLE \(tablename) SUCESS ")
                resultHandler?(true, nil)
            }
        }
        
    }
}


//typealias SQLiteColumn = (column: String, type: SQLiteDataType)

struct SQLiteColumn {
    var name: String
    var type: SQLiteDataType
    var isUnique: Bool = false
    init(name: String, type: SQLiteDataType, isUnique: Bool = false) {
        self.name = name
        self.type = type
        self.isUnique = isUnique
    }
}

enum SQLiteDataType: String {
    case INTEGER = "INTEGER"
    case REAL = "REAL"
    case TEXT = "TEXT"
    case MEDIUMTEXT = "MEDIUMTEXT" // 最大16M
    case BOOLEAN = "BOOLEAN"
    case TIMESTAMP = "timestamp"
}

enum SQLError: Error {
    case unopen(msg: String)
    case unexpected(msg: String)
}
