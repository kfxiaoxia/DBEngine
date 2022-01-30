//
//  DBEngineTests.swift
//  DBEngineTests
//
//  Created by zhifou on 1/30/22.
//

import XCTest
@testable import DBEngine

class DBEngineTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testdb_01_DropTable() throws {
        DBEngine.shared.dropTable("tab_user_info") { res, error in
            XCTAssertEqual(res, true)
        }
    }
    
    func testdb_02_CreateTable() throws {
        let clos: [SQLiteColumn] = [
            SQLiteColumn.init(name: "user_id", type: .INTEGER, isUnique: true),
            SQLiteColumn.init(name: "name", type: .TEXT),
            SQLiteColumn.init(name: "age", type: .INTEGER),
            SQLiteColumn.init(name: "gender", type: .BOOLEAN),
            SQLiteColumn.init(name: "balance", type: .REAL),
            SQLiteColumn.init(name: "avatar", type: .TEXT)
        ]
        
        DBEngine.shared.createTable("tab_user_info", columns: clos) { res, error in
            XCTAssertEqual(res, true)
        }
    }
    
    func testdb_03_UpdateRecordsIfAlreadyExistsReplaceElseInsert() throws {
        
        let pars: [String: Any] = [
            "user_id": 1, "name": "kfxiaoxia", "age": 28, "gender": true, "balance": 9872
        ]
        DBEngine.shared.update("tab_user_info", pars: pars) { res, error in
            
            XCTAssertEqual(res, true)

        }
    }
    
    
    func testdb_04_UpdateRecordsWithTransactionIfAlreadyExistsReplaceElseInsert() throws {
        let pars: [[String: Any]] = [
            ["user_id": 1, "name": "kfxiaoxia1", "age": 28, "gender": true, "balance": 9872],
            ["user_id": 2, "name": "kfxiaoxia2", "age": 28, "gender": true, "balance": 9872],
            ["user_id": 3, "name": "kfxiaoxia3", "age": 28, "gender": true, "balance": 9872],
            ["user_id": 4, "name": "kfxiaoxia4", "age": 28, "gender": true, "balance": 9872]
        ]
        
        DBEngine.shared.updateWithTransaction(tablename: "tab_user_info", records: pars) { res, error in
            XCTAssertEqual(res, true)
        }
    }
    
    
    
    func testdb_05_QueryAllRecords() throws {
        
        DBEngine.shared.query("tab_user_info", conditions: [:]) { res, error, lists in
            XCTAssertEqual(res, true)
        }
    }
    
    
    func testdb_06_QueryRecordsWithConditions() throws {
        
        let conditions: [String: Any] = [
            "user_id": 2
        ]
        
        DBEngine.shared.query("tab_user_info", conditions: conditions) { res, error, lists in
            XCTAssertEqual(res, true)
        }
    }
    
    
    func testdb_07_DropRecordsWithConditions() throws {
        let conditions: [String: Any] = [
            "user_id": 1
        ]
        DBEngine.shared.dropRecords("tab_user_info", conditions: conditions) { res, error in
            XCTAssertEqual(res, true)
        }
    }
    
    
    
}
