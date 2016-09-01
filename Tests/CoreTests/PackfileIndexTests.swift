//
//  PackfileIndexTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class PackfileIndexTests: XCTestCase {
    
    let index = PackfileIndex(name: "pack-a74bd7bba3ae75e0093b5b120b103cbab5340e59.idx", repository: packedRepository)!

    func testReadAll() {
        let entries = index.readAll()
        let expected = [
            "39f6140dee77ffed9539d61aead2e1239ac7ad13": 12,
            "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717": 170,
            "29287d7a61db5b55e66f707a01b7fb4b11efcb40": 267,
            "e1bb0a84098498cceea87cb6b542479a4b9e769d": 423,
            "041383a1bfc1f3ded2318db09d11b1dc8de629dd": 584,
            "94e72a122b9099798132e971eaccf727c1ff037d": 740,
            "f3be9f51189c34537e68df056f0cafae59d63b96": 899,
            "8b94ed70009df594c0569a8a1e37a6025397b299": 1026,
            "1f1ace28d590693be994c10b3c2895cb62da6229": 1104,
            "5e5176fa30d950855ef3a9b9050111328b968971": 1250,
            "11bbaed2e1c68b714e12e35615aedbe3c2a4e760": 1300,
            "1f9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5": 1317,
            "1209fb65536f4ef7f72c8f87a7724074ffb5e57e": 1334,
            "d2285a22610b068c9fd9f25fd548e76d27fee860": 1412,
            "45973d6219ba7e61bd3589cae5d24bd1406ec8fa": 1459,
            "4260dd4b89d8b3f9a231538664bd3d346fdd2ead": 1505,
            "234496b1caf2c7682b8441f9b866a7e2420d9748": 1544,
            "3a79a681b63d71c6c7c22bdefcb3e4e8d3988a5b": 1559,
            "aa3350c980eda0524c9ec6db48a613425f756b68": 1598,
            "e20f5916c1cb235a7f26cd91e09a40e277d38306": 1626,
            "6b3b273987213e28230958801876aff0876376e7": 1659,
            "1c59427adc4b205a270d8f810310394962e79a8b": 1696,
            "220f4aa98a71f6767d753148383fc4c941d4d071": 1717
        ]
        for entry in entries {
            guard let offset = expected[entry.hash] else {
                XCTFail()
                break
            }
            XCTAssert(entry.offset == offset)
        }
    }
    
    func testIndividualOffset() {
        XCTAssert(index.offset(for: "39f6140dee77ffed9539d61aead2e1239ac7ad13") == 12)
        XCTAssert(index.offset(for: "f3be9f51189c34537e68df056f0cafae59d63b96") == 899)
        XCTAssert(index.offset(for: "d2285a22610b068c9fd9f25fd548e76d27fee860") == 1412)
        XCTAssert(index.offset(for: "1c59427adc4b205a270d8f810310394962e79a8b") == 1696)
        XCTAssert(index.offset(for: "220f4aa98a71f6767d753148383fc4c941d4d071") == 1717)
        XCTAssert(index.offset(for: "22aaaaa98a71faaa7d753148383fc4c941aaa071") == nil) // Random hash not in pack
    }
    
    func testCount() {
        XCTAssert(packedRepository.packfileIndices.count == 1)
    }

}
