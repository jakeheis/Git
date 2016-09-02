//
//  Data+Crypto.swift
//  Crypto
//
//  Created by Sam Soffes on 4/21/15.
//  Copyright (c) 2015 Sam Soffes. All rights reserved.
//

import Foundation
import CommonCrypto

// TODO: taken from https://github.com/soffes/Crypto until it has a Package.swift

extension Data {

	// MARK: - Digest

	public var sha1: Data {
		return digest(Digest.sha1)
	}

	private func digest(_ function: ((UnsafeRawPointer, UInt32) -> [UInt8])) -> Data {
		var hash: [UInt8] = []
		withUnsafeBytes { hash = function($0, UInt32(count)) }
		return Data(bytes: hash, count: hash.count)
	}
}

public struct Digest {
    
    public static func sha1(bytes: UnsafeRawPointer, length: UInt32) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1(bytes, length, &hash)
        return hash
    }
    
}
