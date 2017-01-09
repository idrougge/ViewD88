//
//  D88-test.swift
//  Checks rely on a 2D BASIC format D88 image. Some of the tests tend to test the image itself rather than the functions.
//
//  Created by Iggy Drougge on 2017-01-09.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import XCTest

class D88_test: XCTestCase {
    
    var diskimage:D88Image!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let imgpath = URL(fileURLWithPath: NSHomeDirectory()+"/Documents/d88-swift/basic.d88")
        guard let imgdata = try? Data(contentsOf: imgpath) else { fatalError("Fel vid inläsning av fil")}
        diskimage = D88Image(data: imgdata)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    func testGotTracks() {
        XCTAssert(diskimage.tracks >= 40)
    }
    func testValidTrackTable() {
        let firstzero = diskimage.tracktable.index(of: 0) ?? diskimage.tracktable.endIndex
        _=diskimage.tracktable[0..<firstzero].reduce(UInt32(0)){
                XCTAssert($1>$0)
                return $1
        }
        let henceforthallzeros = diskimage.tracktable[firstzero..<diskimage.tracktable.endIndex].reduce(UInt32(0)){$0+$1} == 0
        XCTAssert(henceforthallzeros)
    }
    func testGetFiles() {
        let files = diskimage.getFiles()
        XCTAssert( files.count > 0 )
    }
    func testIsBasicFilesystem() {
        XCTAssert(diskimage.filesystem == .basic)
    }
    func testDiskHeader() {
        XCTAssert(diskimage.surfaces > 0 && diskimage.surfaces <= 2)
        XCTAssert(diskimage.type == .D88)
    }
    func testCorrectSize() {
        XCTAssert(Int(diskimage.header.disksize) == diskimage.data.count)
    }
}
