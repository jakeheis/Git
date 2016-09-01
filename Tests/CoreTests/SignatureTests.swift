//
//  SignatureTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class SignatureTests: XCTestCase {

    func testParse() {
        let signature = Signature(signature: "Jake Heiser <jakeheiser1@gmail.com> 1472702718 -0500")
        XCTAssert(signature.name == "Jake Heiser")
        XCTAssert(signature.email == "jakeheiser1@gmail.com")
        XCTAssert(signature.time == Date(timeIntervalSince1970: 1472702718))
        XCTAssert(signature.timeZone == TimeZone(identifier: "GMT-0500"))
    }

}
