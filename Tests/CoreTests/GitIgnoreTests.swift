//
//  GitIgnoreTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class GitIgnoreTests: XCTestCase {

    func testComment() {
        XCTAssert(GitIgnoreEntry("# Hello") == nil)
        XCTAssert(GitIgnoreEntry(" ") == nil)
    }
    
    func testBasicMatch() {
        let entry = GitIgnoreEntry(".build")!
        
        XCTAssert(entry.matches(".build"))
        XCTAssert(entry.matches(".build/file"))
        XCTAssert(entry.matches("folder/.build"))
        XCTAssert(entry.matches("folder/.build/file"))
        XCTAssert(entry.matches("folder/subfolder/.build"))
        
        XCTAssert(!entry.matches("build"))
        XCTAssert(!entry.matches(".buildd"))
    }
    
    func testLeadingSlashMatch() {
        let entry = GitIgnoreEntry("/.build")!
        
        XCTAssert(entry.matches(".build"))
        XCTAssert(entry.matches(".build/file"))
        
        XCTAssert(!entry.matches("folder/.build"))
        XCTAssert(!entry.matches("folder/.build/file"))
        XCTAssert(!entry.matches("build"))
    }

    func testWildcardMatch() {
        let entry = GitIgnoreEntry("*.xcodeproj")!
        
        XCTAssert(entry.matches("Hi.xcodeproj"))
        XCTAssert(entry.matches("Hello.xcodeproj"))
        XCTAssert(entry.matches("Hello.xcodeproj/file"))
        XCTAssert(entry.matches("folder/Hello.xcodeproj/file"))
        XCTAssert(entry.matches(".xcodeproj"))
        XCTAssert(entry.matches("folder/subfolder/.xcodeproj/file"))
        
        XCTAssert(!entry.matches("Hi.xcodeprojj"))
        XCTAssert(!entry.matches("xcodeproj"))
    }
    
    func testTrailingSlashMatch() {
        let entry = GitIgnoreEntry("build/")!
        
        XCTAssert(entry.matches("build", directory: true))
        XCTAssert(entry.matches("build/subfile"))
        XCTAssert(entry.matches("folder/build", directory: true))
        XCTAssert(entry.matches("folder/build/subfile"))
        XCTAssert(entry.matches("folder/build/subdirectory", directory: true))
        
        XCTAssert(!entry.matches("build", directory: false))
        XCTAssert(!entry.matches("folder/build", directory: false))
        XCTAssert(!entry.matches(".build"))
    }
    
    func testMidSlashMatch() {
        let entry = GitIgnoreEntry("Documentation/*.html")!
        
        XCTAssert(entry.matches("Documentation/git.html"))
        
        XCTAssert(!entry.matches("Documentation/ppc/git.html"))
        XCTAssert(!entry.matches("folder/Documentation/git.html"))
    }
    
    func testLeadingDoubleAsterisk() {
        let entry = GitIgnoreEntry("**/Documentation/*.html")!
        
        XCTAssert(entry.matches("Documentation/git.html"))
        XCTAssert(entry.matches("folder/Documentation/git.html"))
        
        XCTAssert(!entry.matches("Documentation/ppc/git.html"))
    }
    
    func testTrailingDoubleAsterisk() {
        let entry = GitIgnoreEntry("abc/**")!
        
        XCTAssert(entry.matches("abc"))
        XCTAssert(entry.matches("abc/hi"))
        
        XCTAssert(!entry.matches("folder/abc"))
        XCTAssert(!entry.matches("folder/abc/hi"))
    }
    
    func testMiddleDoubleAsterisk() {
        let entry = GitIgnoreEntry("a/**/c")!
        
        XCTAssert(entry.matches("a/c"))
        XCTAssert(entry.matches("a/0/c"))
        XCTAssert(entry.matches("a/1/2/c"))
        
        XCTAssert(!entry.matches("b/c"))
        XCTAssert(!entry.matches("a/b"))
    }
    
}
