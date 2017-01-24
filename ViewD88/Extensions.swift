//
//  Extensions.swift
//  Extensions for Integer, Array and Data
//
//  Created by Iggy Drougge on 2017-01-07.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Foundation

extension Integer {
    func hex() -> String {
        return "$"+String(format:"%x", self as! CVarArg)
    }
}

extension ContiguousArray where Element:UnsignedInteger {
    init(_ data:Data){
        let datasize = data.count / MemoryLayout<Element>.size
        self = ContiguousArray<Element>(repeating: 0, count: datasize)
        _=self.withUnsafeMutableBufferPointer{ dest in
            data.copyBytes(to: dest)
        }
    }
}

extension Data {
    func copyInto<T>( dest:inout T, from: Data.Index, to: Data.Index) {
        print("copyInto", from, to, type(of: T.self))
        return self.subdata(in: from ..< to).withUnsafeBytes{
            return $0.pointee
        }
    }
    func get<T>(from: Data.Index, to: Data.Index) -> T {
        //print("Data.get", from, to, type(of: T.self))
        return self.subdata(in: from ..< to).withUnsafeBytes{ $0.pointee }
    }
    func hexdump() -> String {
        return self.reduce(""){ $0 + String(format: "%02x ",$1) }
    }
    func ascii() -> String {
        return String(data: self, encoding: .ascii) ?? "Data with illegal encoding"
    }
    func cleanAscii() -> String {
        let filtered = self.filter{
            !CharacterSet.controlCharacters.contains(UnicodeScalar($0) )
        }
        return String(bytes: filtered, encoding: .ascii) ?? "Data with illegal encoding"
    }
}

extension Float32 {
    /// Create float value from 4 byte array representing a Microsoft binary single precision float
    init(mssingle bytes:[UInt8]) {
        // 00 00 00 91 = 65536!
        var ieee = bytes
        ieee[3] = bytes[2] & 0x80 // sign bit
        let ieee_exp = bytes[3] - 2
        ieee[3] |= ieee_exp >> 1
        ieee[2] = ieee_exp << 7
        ieee[2] |= (bytes[2] & 0x7f) //  0111 1111
        let f:Float32 = Data(ieee).withUnsafeBytes{$0.pointee}
        self = f
    }
}

extension Float64 {
    /// Create double precision float from an 8 byte array representing a MS binary double precision float
    init(msdouble bytes:[UInt8]) {
        var msbin = bytes
        var ieee = [UInt8](repeatElement(0, count: 8))
        guard msbin.count == 8, msbin[7] != 0 else { self = 0 ; return }
        ieee[7] = msbin[6] & 0x80 // Sign bit
        let exp = UInt(msbin[7]) &- 128 &- 1 &+ 1023
        ieee[7] |= UInt8( (exp >> 4) & 0xff )
        ieee[6] = UInt8( (exp << 4) & 0xff )
        // FIXME: Strides inside number extensions will not work due to a Swift 3 bug.
        //for i in stride(from: 6, to: 0, by: -1) {
        var i = 6
        while i > 0 {
            msbin[i] <<= 1
            msbin[i] |= msbin[i-1] >> 7
            i -= 1
        }
        msbin[0] <<= 1
        //for i in stride(from: 6, to: 0, by: -1) {
        i = 6
        while i > 0 {
            ieee[i] |= msbin[i] >> 4
            ieee[i-1] |= msbin[i] << 4
            i -= 1
        }
        ieee[0] |= msbin[0] >> 4
        let f:Float64 = Data(ieee).withUnsafeBytes{ $0.pointee }
        self = f
    }
}

