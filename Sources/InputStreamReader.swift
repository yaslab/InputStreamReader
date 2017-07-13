//
//  InputStreamReader.swift
//  InputStreamReader
//
//  Created by Yasuhiro Hatta on 2017/07/13.
//  Copyright © 2017 yaslab. All rights reserved.
//

import Foundation
import CIconv

public class InputStreamReader: InputStream {
    
    public enum Encoding: String {
        case utf8 = "UTF-8"
        case shiftJIS = "SHIFT_JIS"
    }
    
    private let innerSteram: InputStream
    
    private let cd: iconv_t
    private var inBuffer: UnsafeMutablePointer<UInt8>
    private let inBufferSize: Int
    private var inBytesLeft: Int = 0
    
    private let leaveOpen: Bool
    
    public init(_ stream: InputStream, fromCode: Encoding = .utf8, toCode: Encoding = .utf8, bufferSize: Int = 1024, leaveOpen: Bool = false) {
        self.innerSteram = stream
        self.cd = iconv_open(toCode.rawValue, fromCode.rawValue)
        self.inBuffer = malloc(bufferSize).assumingMemoryBound(to: UInt8.self)
        self.inBufferSize = bufferSize
        self.leaveOpen = leaveOpen
        super.init(data: Data())
        if stream.streamStatus == .notOpen {
            stream.open()
        }
    }
    
    deinit {
        iconv_close(cd)
        free(inBuffer)
        if !leaveOpen && innerSteram.streamStatus == .open {
            innerSteram.close()
        }
    }
    
    // MARK: - InputStream
    
    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        memmove(inBuffer, inBuffer + (inBufferSize - inBytesLeft), inBytesLeft)
        var readLength = innerSteram.read(inBuffer + inBytesLeft, maxLength: inBufferSize - inBytesLeft)
        if readLength <= 0 {
            return readLength
        }
        inBytesLeft = inBufferSize
        
        var outBufferPointer: UnsafeMutablePointer<CChar>? = UnsafeMutableRawPointer(buffer).assumingMemoryBound(to: CChar.self)
        var outBytesLeft = len
        
        while true {
            var isLoopEnd = false
            var inBufferPointer: UnsafeMutablePointer<CChar>? = UnsafeMutableRawPointer(inBuffer).assumingMemoryBound(to: CChar.self)
            
            let ret = iconv(cd, &inBufferPointer, &inBytesLeft, &outBufferPointer, &outBytesLeft)
            if ret == -1 {
                switch errno {
                case E2BIG: // There is not sufficient room at *outbuf.
                    isLoopEnd = true
                case EILSEQ: // An invalid multibyte sequence has been encountered in the input.
                    return -1
                case EINVAL: // An incomplete multibyte sequence has been encountered in the input.
                    memmove(inBuffer, inBufferPointer, inBytesLeft)
                    readLength = innerSteram.read(inBuffer + inBytesLeft, maxLength: inBufferSize - inBytesLeft)
                    if readLength <= 0 {
                        return -1
                    }
                    inBytesLeft = inBufferSize
                default:
                    return -1
                }
            } else if inBytesLeft == 0 {
                memmove(inBuffer, inBufferPointer, inBytesLeft)
                readLength = innerSteram.read(inBuffer + inBytesLeft, maxLength: inBufferSize - inBytesLeft)
                if readLength <= 0 {
                    return -1
                }
                inBytesLeft = inBufferSize
            }
            
            if isLoopEnd {
                break
            }
        }
        
        return len - outBytesLeft
    }
    
    public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        return false
    }
    
    public override var hasBytesAvailable: Bool {
        return innerSteram.hasBytesAvailable
    }
    
    // MARK: - Stream
    
    public override func open() {
        
    }
    
    public override func close() {
        
    }
    
    public override var streamStatus: Stream.Status {
        return innerSteram.streamStatus
    }
    
    public override var streamError: Error? {
        return innerSteram.streamError
    }
    
}
