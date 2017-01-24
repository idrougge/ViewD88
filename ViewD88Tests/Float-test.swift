//
//  Float-test.swift
//  ViewD88
//
//  Created by Iggy Drougge on 2017-01-24.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import XCTest

class Float_test: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFloat32() {
        XCTAssert(Float32(mssingle: [0x00, 0x00, 0x00, 0x91]) == 65536)
    }
    
    func testFloat64() {
        // D7 58 CE 4D B7 E6 47 82 = 3.123456789#
        XCTAssert( Float64(msdouble: [0xD7, 0x58, 0xCE, 0x4D, 0xB7, 0xE6, 0x47, 0x82]) > 3.1234)
        XCTAssert( String(describing: NSNumber(value: Float64(msdouble: [0xD7, 0x58, 0xCE, 0x4D, 0xB7, 0xE6, 0x47, 0x82]))) == "3.123456789")
        // F6 28 5C 8F C2 F5 48 82 = 3.14#
        XCTAssert( String(describing: NSNumber(value: Float64(msdouble: [0xF6, 0x28, 0x5C, 0x8F, 0xC2, 0xF5, 0x48, 0x82]))) == "3.14")
        // 00 00 00 00 00 00 00 91 = 65536#
        XCTAssert( Float64(msdouble: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x91]) == 65536)
        XCTAssert( String(describing: NSNumber(value: Float64(msdouble: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x91]))) == "65536")

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
