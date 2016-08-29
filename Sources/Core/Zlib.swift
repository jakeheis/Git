import Foundation
import Czlib

// Taken directly from https://github.com/Zewo/gzip -- delete this file once they update to Swift 3

public protocol Gzippable {
    associatedtype DataType
    func gzipCompressed() throws -> DataType
    func gzipUncompressed() throws -> DataType
}

extension NSData: Gzippable {
    
    public func gzipCompressed() throws -> NSData {
        return try autoreleasepoolIfAvailable {
            guard self.length > 0 else { return NSData() }
            let uncompressor = GzipCompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self, isLast: true)
            return outData
        }
    }
    
    public func gzipUncompressed() throws -> NSData {
        return try autoreleasepoolIfAvailable {
            guard self.length > 0 else { return NSData() }
            let uncompressor = GzipUncompressor()
            try uncompressor.initialize()
            let outData = try uncompressor.process(data: self, isLast: true)
            return outData
        }
    }
}

public func autoreleasepoolIfAvailable<Result>(_ body: () throws -> Result) rethrows -> Result {
    #if _runtime(_ObjC)
        return try autoreleasepool(invoking: body)
    #else
        return try body()
    #endif
}

private let CHUNK_SIZE: Int = 16384
private let STREAM_SIZE: Int32 = Int32(MemoryLayout<z_stream>.size)

// MARK: - GzipUncmpressor
final class GzipUncompressor: GzipProcessor {
    
    internal var _stream: UnsafeMutablePointer<z_stream>
    internal var closed: Bool = false
    
    init() {
        _stream = _makeStream()
    }
    
    func initialize() throws {
        let result = inflateInit2_(
            &_stream.pointee,
            // MAX_WBITS,
            MAX_WBITS + 32, //+32 to detect gzip header
            ZLIB_VERSION,
            STREAM_SIZE
        )
        guard result == Z_OK else {
            throw GzipError(code: result, message: _stream.pointee.msg)
        }
    }
    
    func process(data: NSData, isLast: Bool) throws -> NSData {
        let mode = isLast ? Z_FINISH : Z_SYNC_FLUSH
        let processChunk: () -> Int32 = { return inflate(&self._stream.pointee, mode) }
        let loop: (_ result: Int32) -> Bool = { _ in self._stream.pointee.avail_in > 0 }
        let shouldEnd: (_ result: Int32) -> Bool = { _ in isLast }
        let end: () -> () = { inflateEnd(&self._stream.pointee) }
        return try self._process(data: data, processChunk: processChunk, loop: loop, shouldEnd: shouldEnd, end: end)
    }
    
    func close() {
        if !closed {
            inflateEnd(&_stream.pointee)
            closed = true
        }
    }
    
    deinit {
        close()
        _clearMemory()
    }
}

// MARK: - GzipCompressor

final class GzipCompressor: GzipProcessor {
    
    internal var _stream: UnsafeMutablePointer<z_stream>
    internal var closed: Bool = false
    
    init() {
        _stream = _makeStream()
    }
    
    func initialize() throws {
        let result = deflateInit2_(
            &_stream.pointee,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            MAX_WBITS + 16, //+16 to specify gzip header
            MAX_MEM_LEVEL,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            STREAM_SIZE
        )
        guard result == Z_OK else {
            throw GzipError(code: result, message: _stream.pointee.msg)
        }
    }
    
    func process(data: NSData, isLast: Bool) throws -> NSData {
        let mode = isLast ? Z_FINISH : Z_SYNC_FLUSH
        let processChunk: () -> Int32 = { return deflate(&self._stream.pointee, mode) }
        let loop: (_ result: Int32) -> Bool = { _ in self._stream.pointee.avail_out == 0 }
        let shouldEnd: (_ result: Int32) -> Bool = { _ in isLast }
        let end: () -> () = { deflateEnd(&self._stream.pointee) }
        return try self._process(data: data, processChunk: processChunk, loop: loop, shouldEnd: shouldEnd, end: end)
    }

    func close() {
        if !closed {
            deflateEnd(&_stream.pointee)
            closed = true
        }
    }
    
    deinit {
        close()
        _clearMemory()
    }
}

func _makeStream() -> UnsafeMutablePointer<z_stream> {
    let stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
    let ptr = UnsafeMutablePointer<z_stream>.allocate(capacity: 1)
    ptr.initialize(to: stream)
    return ptr
}

// MARK: - GzipProcessor

protocol GzipProcessor: class {
    func initialize() throws
    func process(data: NSData, isLast: Bool) throws -> NSData
    func close()
    var closed: Bool { get set }
    var _stream: UnsafeMutablePointer<z_stream> { get }
}

extension GzipProcessor {
    
    func _clearMemory() {
        _stream.deinitialize(count: 1)
        _stream.deallocate(capacity: 1)
    }
    
    func _process(data: NSData,
                  processChunk: () -> Int32,
                  loop: (_ result: Int32) -> Bool,
                  shouldEnd: (_ result: Int32) -> Bool,
                  end: () -> ()) throws -> NSData {
        guard data.length > 0 else { return NSData() }
        
        let rawInput = UnsafeMutableRawPointer(mutating: data.bytes).assumingMemoryBound(to: Bytef.self)
        _stream.pointee.next_in = rawInput
        _stream.pointee.avail_in = uInt(data.length)
        
        guard let output = NSMutableData(capacity: CHUNK_SIZE) else {
            throw GzipError.memory(message: "Not enough memory")
        }
        output.length = CHUNK_SIZE
        
        let chunkStart = _stream.pointee.total_out
        
        var result: Int32 = 0
        repeat {
            if _stream.pointee.total_out >= uLong(output.length) {
                output.length += CHUNK_SIZE;
            }
            
            let writtenBeforeThisChunk = _stream.pointee.total_out - chunkStart
            let availOut = uLong(output.length) - writtenBeforeThisChunk
                        
            _stream.pointee.avail_out = uInt(availOut)
            _stream.pointee.next_out = output.mutableBytes.assumingMemoryBound(to: Bytef.self).advanced(by: Int(writtenBeforeThisChunk))
            
            result = processChunk()

            guard result >= 0 || (result == Z_BUF_ERROR && _stream.pointee.avail_out == 0) else {
                throw GzipError(code: result, message: _stream.pointee.msg)
            }
            
            if _stream.pointee.total_out - chunkStart == writtenBeforeThisChunk { // Didn't read any
                break
            }
        } while loop(result)
        
        guard result == Z_STREAM_END || result == Z_OK else {
            throw GzipError.stream(message: "Wrong result code \(result)")
        }
        if shouldEnd(result) {
            end()
            closed = true
        }
        let chunkCount = _stream.pointee.total_out - chunkStart
        output.length = Int(chunkCount)
        return output
    }
}

// MARK: - GzipError

public enum GzipError: Error {
    //Reference: http://www.zlib.net/manual.html
    
    /// The stream structure was inconsistent.
    case stream(message: String)
    
    ///The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
    case data(message: String)
    
    /// There was not enough memory.
    case memory(message: String)
    
    /// No progress is possible or there was not enough room in the output buffer.
    case buffer(message: String)
    
    /// The zlib library version is incompatible with the version assumed by the caller.
    case version(message: String)
    
    /// An unknown error occurred.
    case unknown(message: String, code: Int)
    
    internal init(code: Int32, message cmessage: UnsafePointer<CChar>?)
    {
        let message: String
        if let cmessage = cmessage, let msg = String(validatingUTF8: cmessage) {
            message = msg
        } else {
            message = "unknown gzip error"
        }
        switch code {
        case Z_STREAM_ERROR: self = .stream(message: message)
        case Z_DATA_ERROR: self = .data(message: message)
        case Z_MEM_ERROR: self = .memory(message: message)
        case Z_BUF_ERROR: self = .buffer(message: message)
        case Z_VERSION_ERROR: self = .version(message: message)
        default: self = .unknown(message: message, code: Int(code))
        }
    }
}
