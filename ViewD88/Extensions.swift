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
