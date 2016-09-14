//
//  Stat.swift
//  Git
//
//  Created by Jake Heiser on 9/7/16.
//
//

import Foundation
import FileKit

public struct Stat {
    
    public let cSeconds: Int
    public let cNanoseconds: Int
    public let mSeconds: Int
    public let mNanoseconds: Int
    public let dev: Int
    public let ino: Int
    public let mode: FileMode
    public let uid: Int
    public let gid: Int
    public let fileSize: Int
    
    public var cDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(cSeconds + cNanoseconds / 1_000_000_000))
    }
    
    public var mDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(mSeconds + mNanoseconds / 1_000_000_000))
    }
    
    init(mode: FileMode) {
        self.cSeconds = 0
        self.cNanoseconds = 0
        self.mSeconds = 0
        self.mNanoseconds = 0
        self.dev = 0
        self.ino = 0
        self.mode = mode
        self.uid = 0
        self.gid = 0
        self.fileSize = 0
    }
    
    init(path: Path) {
        let pathPointer = path.rawValue.cString(using: .ascii)
        let statPointer = UnsafeMutablePointer<stat>.allocate(capacity: 1)
        lstat(pathPointer, statPointer)
        
        guard let fileMode = FileMode(rawValue: String(statPointer.pointee.st_mode, radix: 8)) else {
            fatalError("Unrecognized flie mode: \(statPointer.pointee.st_mode)")
        }
        
        cSeconds = statPointer.pointee.st_ctimespec.tv_sec
        cNanoseconds = statPointer.pointee.st_ctimespec.tv_nsec
        mSeconds = statPointer.pointee.st_mtimespec.tv_sec
        mNanoseconds = statPointer.pointee.st_mtimespec.tv_nsec
        dev = Int(statPointer.pointee.st_dev)
        ino = Int(statPointer.pointee.st_ino)
        mode = fileMode
        uid = Int(statPointer.pointee.st_uid)
        gid = Int(statPointer.pointee.st_gid)
        fileSize = Int(statPointer.pointee.st_size)
        
        statPointer.deallocate(capacity: 1)
    }
    
    init(cSeconds: Int, cNanoseconds: Int, mSeconds: Int, mNanoseconds: Int, dev: Int, ino: Int, mode: FileMode, uid: Int, gid: Int, fileSize: Int){
        self.cSeconds = cSeconds
        self.cNanoseconds = cNanoseconds
        self.mSeconds = mSeconds
        self.mNanoseconds = mNanoseconds
        self.dev = dev
        self.ino = ino
        self.mode = mode
        self.uid = uid
        self.gid = gid
        self.fileSize = fileSize
    }
    
}

extension Stat: Equatable {}

public func == (lhs: Stat, rhs: Stat) -> Bool {
    return lhs.cSeconds == rhs.cSeconds && lhs.cNanoseconds == rhs.cNanoseconds && lhs.mSeconds == rhs.mSeconds && lhs.mNanoseconds == rhs.mNanoseconds && lhs.dev == rhs.dev && lhs.ino == rhs.ino && lhs.mode == rhs.mode && lhs.uid == rhs.uid && lhs.gid == rhs.gid && lhs.fileSize == rhs.fileSize
}
