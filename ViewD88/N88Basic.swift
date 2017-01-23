//
//  N88Basic.swift
//  ViewD88
//
//  Created by Iggy Drougge on 2017-01-21.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Foundation

struct N88basic {
    enum Token:UInt8 {
        case newline = 0x00
        case octal = 0x0b
        case hexadecimal = 0x0c
        case linenumber = 0x0d
        case linenumberafterexec = 0x0e
        case smallinteger = 0x0f
        case verysmallinteger = 0x11 //...0x1a
        case biginteger = 0x1c
        case float = 0x1d
        case double = 0x1f
        case keyword = 0x81 // ...0xfe
        case ffkeyword = 0xff
        case quote = 0x22
        case literal = 0x40
        //case illegal = -1
        /// Number of bytes used as argument to token
        func bytes() -> Int {
            switch self {
            case .newline: return 4 // Newline is followed by linkpointer (two bytes) and linenumber (two bytes)
            case .literal: return 0
            case .keyword: return 0
            case .ffkeyword: return 1
            case .quote: return 0
            case .smallinteger: return 1
            case .verysmallinteger: return 0
            case .biginteger: return 2
            case .octal: return 2
            case .hexadecimal: return 2
            case .linenumber: return 2
            case .linenumberafterexec: return 2
            case .float: return 4
            case .double: return 8
                //case .illegal: return 0
            }
        }
        init(_ key:UInt8) {
            if let t = Token(rawValue: key) {
                self = t
                return
            }
            switch key {
            case 0x81...0xfe: self = .keyword
            case 0x11...0x1a: self = .verysmallinteger
            default: self = .literal
            }
        }
    }
    
    static let keywords:[UInt8:String] = [
        0x81: "END",	0x82: "FOR",	0x83: "NEXT",	0x84: "DATA",	0x85: "INPUT",	  0x86: "DIM",      0x87: "READ",
        0x88: "LET",	0x89: "GOTO",	0x8A: "RUN",	0x8B: "IF",     0x8C: "RESTORE",  0x8D: "GOSUB",	0x8E: "RETURN",
        0x8F: "REM",	0x90: "STOP",	0x91: "PRINT",	0x92: "CLEAR",	0x93: "LIST",	  0x94: "NEW",      0x95: "ON",
        0x96: "WAIT",	0x97: "DEF",	0x98: "POKE",	0x99: "CONT",	0x9A: "OUT",	  0x9B: "LPRINT",	0x9C: "LLIST",
        0x9D: "CONSOLE",0x9E: "WIDTH",	0x9F: "ELSE",	0xA0: "TRON",	0xA1: "TROFF",	  0xA2: "SWAP",     0xA3: "ERASE",
        0xA4: "EDIT",	0xA5: "ERROR",	0xA6: "RESUME",	0xA7: "DELETE",	0xA8: "AUTO",	  0xA9: "RENUM",	0xAA: "DEFSTR",
        0xAB: "DEFINT",	0xAC: "DEFSNG",	0xAD: "DEFDBL",	0xAE: "LINE",	0xAF: "WHILE",	  0xB0: "WEND",     0xB1: "CALL",
        0xB5: "WRITE",	0xB6: "COMMON",	0xB7: "CHAIN",	0xB8: "OPTION",	0xB9: "RANDOMIZE",0xBA: "DSKO$",	0xBB: "OPEN",
        0xBC: "FIELD",	0xBD: "GET",	0xBE: "PUT",	0xBF: "SET",	0xC0: "CLOSE",	  0xC1: "LOAD",     0xC2: "MERGE",
        0xC3: "FILES",	0xC4: "NAME",	0xC5: "KILL",	0xC6: "LSET",	0xC7: "RSET",	  0xC8: "SAVE",     0xC9: "LFILES",
        0xCA: "MON",	0xCB: "COLOR",	0xCC: "CIRCLE",	0xCD: "COPY",	0xCE: "CLS",	  0xCF: "PSET",     0xD0: "PRESET",
        0xD1: "PAINT",	0xD2: "TERM",	0xD3: "SCREEN",	0xD4: "BLOAD",	0xD5: "BSAVE",	  0xD6: "LOCATE",	0xD7: "BEEP",
        0xD8: "ROLL",	0xD9: "HELP",	0xDB: "KANJI",	0xDC: "TO",     0xDD: "THEN",     0xDE: "TAB(",     0xDF: "STEP",
        0xE0: "USR",	0xE1: "FN",     0xE2: "SPC(",	0xE3: "NOT",	0xE4: "ERL",	  0xE5: "ERR",      0xE6: "STRING$",
        0xE7: "USING",	0xE8: "INSTR",	0xEA: "VARPTR",	0xEB: "ATTR$",	0xEC: "DSKI$",    0xED: "SRQ",      0xEE: "OFF",
        0xEF: "INKEY$",	0xF0: ">",      0xF1: "=",      0xF2: "<",      0xF3: "+",        0xF4: "-",        0xF5: "*",
        0xF6: "/",      0xF7: "^",      0xF8: "AND",	0xF9: "OR",     0xFA: "XOR",	  0xFB: "EQV",      0xFC: "IMP",
        0xFD: "MOD",	0xFE: "\\"]
    static let ffkeywords:[UInt8:String] =
        [0x81: "LEFT$",		0x82: "RIGHT$",		0x83: "MID$",		0x84: "SGN",		0x85: "INT",		0x86: "ABS",
         0x87: "SQR",		0x88: "RND",		0x89: "SIN",		0x8A: "LOG",		0x8B: "EXP",		0x8C: "COS",
         0x8D: "TAN",		0x8E: "ATN",		0x8F: "FRE",		0x90: "INP",		0x91: "POS",		0x92: "LEN",
         0x93: "STR$",		0x94: "VAL",		0x95: "ASC",		0x96: "CHR$",		0x97: "PEEK",		0x98: "SPACE$",
         0x99: "OCT$",		0x9A: "HEX$",		0x9B: "LPOS",		0x9C: "CINT",		0x9D: "CSNG",		0x9E: "CDBL",
         0x9F: "FIX",		0xA0: "CVI",		0xA1: "CVS",		0xA2: "CVD",		0xA3: "EOF",		0xA4: "LOC",
         0xA5: "LOF",		0xA6: "FPOS",		0xA7: "MKI$",		0xA8: "MKS$",		0xA9: "MKD$",		0xD0: "DSKF",
         0xD1: "VIEW",		0xD2: "WINDOW",		0xD3: "POINT",		0xD4: "CSRLIN",		0xD5: "MAP",		0xD6: "SEARCH",
         0xD7: "MOTOR",		0xD8: "PEN",		0xD9: "DATE$",		0xDA: "COM",		0xDB: "KEY",		0xDC: "TIME$",
         0xDD: "WBYTE",		0xDE: "RBYTE",		0xDF: "POLL",		0xE0: "ISET",		0xE1: "IEEE",		0xE2: "IRESET",
         0xE3: "STATUS",	0xE4: "CMD"]
    static func parse(imgdata:Data) -> String {
        var sourceline:[UInt8] = [0x54, 0x45, 0x58, 0x54, 0x2E, 0x54, 0x4F, 0x50, 0xF1, 0xFF, 0x97, 0x28, 0x0C, 0x59, 0xE6, 0x29, 0xF5, 0x1C, 0x00]
        //sourceline = Array(imgdata[0..<128])
        sourceline = Array(imgdata)
        let startptr = Int(sourceline[0])
        guard startptr < sourceline.count, sourceline[startptr] == 0x00 else { fatalError("Pointer to program start invalid") }
        sourceline = Array(sourceline.dropFirst(startptr))
        var line = ""
        var fulltext = ""
        sourceline.removeFirst()
        line = "\(Int(sourceline.removeFirst()) + Int(sourceline.removeFirst())*256) "
        var isString = false
        mainloop:
            while !sourceline.isEmpty {
                let k = sourceline.removeFirst()
                let t = Token(k)
                guard sourceline.count >= t.bytes() else { break }
                if t == .quote {
                    isString = !isString
                    line += "\""
                    //let endquote = sourceline.index(of: Token.quote.rawValue) ?? 0
                    //line += String(bytes: sourceline.prefix(through: endquote), encoding: .shiftJIS) ?? "?"
                    continue
                }
                if isString {
                    line += String(bytes: [k], encoding: .shiftJIS) ?? "?"
                    continue
                }
                let args:[UInt8] = Array(sourceline[0..<t.bytes()])
                sourceline.removeFirst(t.bytes())
                //print(t)
                switch t {
                case .literal: line += String(bytes: [k], encoding: .ascii) ?? "?"
                case .keyword: //print(Keyword(rawValue: k) ?? "?")
                    line += (N88basic.keywords[k] ?? "?")
                case .ffkeyword: line += N88basic.ffkeywords[args.first!] ?? "?"
                case .verysmallinteger: line += "\(k & 0x0f - 1)"
                case .smallinteger: line += "\(args)"
                case .biginteger: line += "\((Int(args[0]) + Int(args[1])*256))"
                case .hexadecimal: line += (String(format: "&H%X%02X", args[1], args[0]))
                case .linenumberafterexec, .linenumber: line += "\(Int(args[0]) + Int(args[1])*256)"
                case .float:
                    // 00 00 00 91 = 65536!
                    var ieee = args
                    ieee[3] = args[2] & 0x80 // sign bit
                    let ieee_exp = args[3] - 2
                    ieee[3] |= ieee_exp >> 1
                    ieee[2] = ieee_exp << 7
                    ieee[2] |= (args[2] & 0x7f) //  0111 1111
                    let f:Float32 = Data(ieee).withUnsafeBytes{$0.pointee}
                    line += String(format: "%*.*F!", f)
                case .double:
                    // FIXME
                    line += "DOUBLE PRECISION FLOATING POINT VALUE / 倍密実数"
                case .octal:
                    line += (String(format: "&O%o%02o", args[1], args[0]))
                case .newline where args[0] | args[1] == 0: // Reached EOT marker
                    print(line)
                    fulltext += line
                    return fulltext
                    //break mainloop
                case .newline:
                    print(line)
                    fulltext += line + "\n"
                    line = "\(Int(args[2]) + Int(args[3])*256) "
                default: print(k,t)
                }
        }
        return fulltext
    }
}
