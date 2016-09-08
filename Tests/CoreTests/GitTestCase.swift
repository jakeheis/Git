//
//  GitTestCase.swift
//  Git
//
//  Created by Jake Heiser on 9/7/16.
//
//

import XCTest

class GitTestCase: XCTestCase {
    
    override func tearDown() {
        TestRepositories.reset()
    }
    
}
