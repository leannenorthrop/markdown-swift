//
//  GruberDialectTests.swift
//  Markdown
//
//  Created by Leanne Northrop on 16/06/2015.
//  Copyright (c) 2015 Leanne Northrop. All rights reserved.
//

import XCTest

class GruberDialectTests: XCTestCase {
    var gruberDialect : GruberDialect! = nil
    
    override func setUp() {
        super.setUp()
        self.gruberDialect = GruberDialect()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSimpleLevel1HeaderBlock() {
        var line = Line(text: "# This is a level 1 heading", lineNumber: 0, trailing: "\n\n")
        
        var result = self.gruberDialect.block["atxHeader"]!(line, Lines())
        
        XCTAssertNotNil(result)
        var r = result![0]
        XCTAssertTrue(r.count > 0)
        XCTAssertEqual("header", r[0] as! String)
        XCTAssertEqual("This is a level 1 heading", r[2] as! String)
        XCTAssertNotNil(r[1])
        XCTAssertNotNil(r[1]["level"])
        XCTAssertEqual(1, r[1]["level"] as! Int)
    }

}