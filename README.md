# DBEngine

**Swift tool library based on FMDB wrapper**



****

```swift
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
```
