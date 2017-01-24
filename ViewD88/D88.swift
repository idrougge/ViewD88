//
//  D88.swift
//  Struct for D88 disk images used by NEC PC-8801 emulators
//
//  Created by Iggy Drougge on 2017-01-07.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Foundation

typealias Byte=UInt8
typealias Word=UInt16
typealias LongWord=UInt32

enum DiskimageFormat {
    case D88
    case _2D
}
protocol Diskimage{}

protocol File {
    var name:String {get}
    var size:Int {get}
}

struct D88Image:Diskimage {
    let type:DiskimageFormat = .D88
    enum Filesystem {
        case n88basic
        case microdiskbasic
        case custom
    }
    struct Sector:CustomStringConvertible {
        let c:Byte  // track
        let h:Byte  // head
        let r:Byte  // sector
        let n:Byte  // length
        let sectorcount:Word
        let density:Byte
        let deleted:Byte
        let status:Byte
        let padding:(Byte,Byte,Byte,Byte,Byte)
        let sectorsize:Word
        var tracklength:Int {
            get {
                return Int(sectorcount * sectorsize)
            }
        }
        var description:String {
            return "Cyl: \(c) Head: \(h) Sector: \(r) Sectorlength: \(n) Sectors: \(sectorcount) Sector size: \(sectorsize)"
        }
        // FIXME: Incorrect image format (MESS format) may report head counts > 2
        init(data:Data) {
            self = data.get(from: data.startIndex, to: data.endIndex)
        }
    }
    
    struct DiskHeader {
        enum Disktype:Int{
            case _2D  = 0x00 // DS/DD 40 tracks
            case _2DD = 0x10 // DS/DD 80 tracks
            case _2HD = 0x20 // DS/HD 80 tracks
            case _1D  = 0x40 // SS/DD 40 tracks
        }
        let label:String
        let wrp:Bool
        let disktype:Disktype
        var disksize:UInt32=0xFFFFFFFF
        init(data:Data){
            self.label = data.withUnsafeBytes{ (src:UnsafePointer<CChar>) -> String in return String(cString: src) }
            self.wrp = data[26] == 0x10
            self.disktype = Disktype(rawValue: Int(data[27])) ?? ._2D
            self.disksize = data.get(from: 28, to: 32)
            print("Skapade DiskHeader med storlek \(disksize) byte av disktyp \(disktype), \(wrp ? "" : "ej") skrivskyddad och namn \"\(label)\"")
        }
    }
    enum FATcell{
        case empty
        case reserved
        case cluster(next:UInt8)
        case sector(last:Int)
        case bad
        init(_ nr: UInt8){
            switch nr {
            case 0xFF: self = .empty
            case 0xFE: self = .reserved
            case 0x00...0x9F: self = .cluster(next: nr)
            case 0xC1...0xC8: self = .sector(last: Int(nr & 0x0f))
            default: self = .bad
            }
        }
    }
    
    struct Track { // Ett spår borde innehålla en uppsättning sektorer, men de kanske måste beräknas fram
        let c,h,r,n:Int
        let content:[Byte]
    }
    struct FileEntry:File {
        enum Attributes:Int {
            case ASC = 0x00
            case BIN = 0x01
            case BAS = 0x80
            case WRP = 0x10
            case RDP = 0x20
            case RAW = 0x40
            case BAD = 0xFF
        }
        private let forename:String
        private let ext:String
        var name:String {
            get {
                let name = self.forename.trimmingCharacters(in: .whitespaces)
                let ext = self.ext.trimmingCharacters(in: .whitespaces)
                return ext.isEmpty ? name : name + "." + ext
            }
        }
        let attributes:Attributes
        let cluster:UInt8
        let startaddr:UInt16    // Starting address in N88 format is saved in first 16 bits of file entry, ending address in following 16 bits.
        // Subtract 1 from ending address.
        let execaddr:UInt16
        var size:Int = 0
        init(data:Data){
            self.forename = data.subdata(in: 0 ..< 6).cleanAscii()
            self.ext = ( String(data: data.subdata(in: 6 ..< 9), encoding: .ascii) ?? "" ).trimmingCharacters(in: .controlCharacters)
            self.cluster = data[10]
            // FIXME: Below property is only relevant for Disk BASIC
            self.startaddr = data.get(from: 11, to: 13)
            // FIXME: Execution address is apparently not used at all in N88 format
            self.execaddr = data.get(from: 13, to: 15)
            self.attributes = Attributes(rawValue: Int(data[9])) ?? .BAD
        }
    }
    
    internal func listFiles() -> [String] {
        return self.getFiles().map{ $0.name }
    }
    func seekTrack(_ nr: Int) -> Int {
        return Int(tracktable[nr])
    }
    func getTrack(_ nr: Int) -> Data {
        let header = getTrackHeader(nr)
        let from = Int(self.tracktable[nr])
        let tracklength = Int( (header.sectorsize + 16) * header.sectorcount )
        //let to = Int(self.tracktable[nr+1])
        let to = from + tracklength
        return self.data.subdata(in: from ..< to)
    }
    func getTrackHeader(_ nr: Int) -> Sector {
        let offset = Int(self.tracktable[nr])
        let headerdata = self.data.subdata(in: offset ..< offset+16)
        return Sector(data: headerdata)
    }
    func getSector(track: Int, nr: Int) -> (sector: Sector, data: Data)? {
        let trackdata = getTrack(track)
        let trackheaderdata = trackdata.subdata(in: 0..<16)
        let trackheader = Sector(data: trackheaderdata)
        let sectorsize = Int(trackheader.sectorsize)
        let offset = nr * (16 + sectorsize)
        // Offset must not exceed sectorsize * sectorcount
        guard offset <= (sectorsize + 16) * Int(trackheader.sectorcount) else { return nil }
        let sectorheaderdata = trackdata.subdata(in: offset ..< offset + 16)
        let sectordata = trackdata.subdata(in: offset + 16 ..< offset + 16 + sectorsize)
        let sector = Sector(data: sectorheaderdata)
        print("getSector: sector \(sector.r) = \( Int(sector.r) == (nr + Int(1)) ? "OK" : "NOT OK" )")
        return (sector,sectordata)
    }
    func getSectors(track: Int, range: CountableRange<Int>) -> Data {
        let trackdata = getTrack(track)
        let trackheaderdata = trackdata.subdata(in: 0..<16)
        let trackheader = Sector(data: trackheaderdata)
        let sectorsize = Int(trackheader.sectorsize)
        var data = Data()
        for nr in range {
            let offset = nr * (16 + sectorsize)
            //let sectorheaderdata = trackdata.subdata(in: offset ..< offset + 16)
            let sectordata = trackdata.subdata(in: offset+16 ..< offset + 16 + sectorsize)
            data.append(sectordata)
        }
        return data
    }
    func getSectors(track: Int) -> Data {
        let trackheader = getTrackHeader(track)
        let sectorcount = Int(trackheader.sectorcount)
        return getSectors(track: track, range: 0 ..< sectorcount)
    }
    func getFile(file:FileEntry) -> Data {
        return getFile(cluster: file.cluster)
    }
    func getFile(cluster:UInt8) -> Data {
        switch fat[Int(cluster)] {
        case .cluster(let next):
            let (track, sectors) = cluster2phys(cluster: cluster)
            let data = getSectors(track: track, range: sectors)
            return data + getFile(cluster: next)
        case .sector( _):
            let (track, sectors) = cluster2phys(cluster: cluster)
            return getSectors(track: track, range: sectors)
        default: break
        }
        return Data()
    }
    func getFiles(tracknr:Int = 37) -> [FileEntry] {
        var files = [FileEntry]()
        guard case .n88basic = self.filesystem else { return files }
        print("filesystem:",self.filesystem)
        var data = Data()
        let sectorcount = 0 ..< 12
        for nr in sectorcount {
            if let sector = getSector(track: tracknr, nr: nr) {
                data.append(sector.data)
            }
        }
        //print("Got sector data of \(data.count) bytes")
        let entrylength = 16
        let datastride = stride(from: 0, to: data.count, by: entrylength)
        for pos in datastride {
            let entrydata = data.subdata(in: pos ..< pos+16)
            guard entrydata.count == 16 else { break }
            guard entrydata[0] != 0xff else { break }   // 0xff marks end of FAT
            var entry = FileEntry(data: entrydata)
            entry.size = self.getFilesize(file: entry)
            files.append(entry)
        }
        return files
    }
    func getFilesize(file:FileEntry) -> Int {
        print(#function,file)
        var size=0
        var cl = Int(file.cluster)
        guard cl < self.fat.count else { return size }
        print("cl:",cl)
        print("fat:",fat.count)
        // FIXME: Cluster chaining can reach infinite loop
        while cl < 0x9f {
            //print(cl,fat[cl])
            switch self.fat[cl] {
            case .sector(let last):
                return size + (last * 256)  // Hardcoded value is bad
            case .cluster(let next):
                guard Int(next) != cl else { return size }
                size += 2048                // Hardcoded value is bad?
                cl = Int(next)
            default: return size
            }
        }
        return size
    }
    func getFAT() -> [FATcell] {
        let fatSectorNr = 13
        guard let fatSector = getSector(track: fatTrack, nr: fatSectorNr) else {
            return [FATcell](repeatElement(.bad, count: 0x9f))
        }
        return fatSector.data[0...0x9f].map{ FATcell($0) }
    }
    func cluster2phys(cluster:UInt8) -> (Int, CountableRange<Int>) {
        let cluster = Int(cluster)
        let track = cluster >> 1
        let sector = 8 * (cluster % 2)
        var sectorcount = 8
        //guard case .sector(let last) = fat[cluster] else { return (track, sector ..< sector+sectorcount ) }
        switch fat[cluster] {
        case .sector(let last): sectorcount = last
        default: break
        }
        return (track, sector ..< sector+sectorcount)
    }
    fileprivate var data:Data
    fileprivate var fatTrack = 37
    fileprivate var fat:[FATcell] = []
    public let tracks:Int
    public var surfaces:Int
    public var filesystem:Filesystem {
        // If IPL contains string "PPC-8001 Micro Disk Basic" that is the filesystem. Maybe without inital P.
        // One may guard by checking if IPL is reserved in FAT.
        get {   // Cluster 0 = IPL
            switch self.fat[74] {   // If FAT cluster (#74, 75) is reserved, it is likely a Basic filesystem
            case .reserved: return .n88basic
            default:        return .custom
            }
        }
    }
    internal var tracktable:ContiguousArray<LongWord>
    internal var header:DiskHeader
    
    internal var rawData: Data {
        get {
            var rawData = Data()
            for track in 0 ..< tracks {
                let trackdata = getSectors(track: track)
                rawData.append(trackdata)
            }
            return rawData
        }
    }
    
    init(data:Data){
        self.data = data
        self.surfaces = 0
        let tracktable = ContiguousArray<LongWord>(data.subdata(in: 0x20 ..< 0x2b0))
        self.tracktable = tracktable
        self.tracks = tracktable.index(of: 0) ?? tracktable.count
        self.header = DiskHeader(data: data.subdata(in: 0..<32))
        self.surfaces = self.header.disktype == ._1D ? 1 : 2
        self.fat = getFAT()
        print("Created D88 object of \(data.count) bytes with \(surfaces) surfaces and \(tracks) tracks")
    }
}
