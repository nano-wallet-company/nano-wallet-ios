//
//  RaiblocksTests.swift
//  RaiblocksTests
//
//  Created by Zack Shapiro on 1/18/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import XCTest

class RaiblocksTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let w = "334000000000000000000000000000000"
        let one = "1000000000000000000000000000000"
        let x = "2000000000000000000000000000"
        let y = "4000000000000000000000000000"
        let z = "7200000000000000000000000000"

        let a = NSDecimalNumber(string: y)
        let b = NSDecimalNumber(string: x)

        XCTAssert(a.subtracting(b).compare(b) == .orderedSame)

        let t = NSDecimalNumber(string: "335").asRawValue
        let u = NSDecimalNumber(string: "105.25").asRawValue
        let v = NSDecimalNumber(string: "0.00001").asRawValue
        XCTAssert(t.subtracting(u).compare((NSDecimalNumber(string: "229.75")).asRawValue) == .orderedSame)

        let d = Decimal(string: "50")!
        let e = Decimal(string: "5000")!
        print(d + e)


        print(t.subtracting(v))
        XCTAssert(t.subtracting(v).compare((NSDecimalNumber(string: "334.99999")).asRawValue) == .orderedSame)


//        XCTAssert(NSDecimalNumber(value: 500).subtracting(NSDecimalNumber(value: 400)).compare(0) == .orderedSame)

    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
