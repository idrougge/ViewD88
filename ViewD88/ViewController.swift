//
//  ViewController.swift
//  D88-Cocoa
//
//  Created by Iggy Drougge on 2017-01-07.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var table: NSTableView!
    @IBOutlet var textField: NSTextField!
    @IBOutlet var dumpFileButton: NSButton!
    private var diskimage: D88Image?
    private var files: [D88Image.FileEntry] = []
    private var fileurl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textField.isEditable = false
        #if DEBUG
        let imgpath = URL(fileURLWithPath: NSHomeDirectory()+"/Documents/d88-swift/basic.d88")
        fileurl = imgpath
        textField.stringValue = imgpath.lastPathComponent
        if let imgdata = try? Data(contentsOf: imgpath) {
            diskimage = D88Image(data: imgdata)
            files = diskimage!.getFiles()
        }
        #endif
        table.dataSource = self
        table.delegate = self
        table.allowsMultipleSelection = true
        table.doubleAction = #selector(self.didDoubleClickRow)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //print(#function,tableColumn!.identifier)
        let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        switch tableColumn?.identifier.rawValue {
        case let id where id == "nr": cell.textField?.stringValue = "\(row)"
        case "name"?:
            let name = files[row].name
            cell.textField?.stringValue = name
        case "type"?:
            let attr:String!
            switch files[row].attributes {
            case .BAS: attr = NSLocalizedString("filetype.BAS", comment: "")
            case .ASC: attr = NSLocalizedString("filetype.ASC", comment: "")
            case .BIN: attr = NSLocalizedString("filetype.BIN", comment: "")
            case .RAW: attr = NSLocalizedString("filetype.RAW", comment: "")
            case .RDP: attr = NSLocalizedString("filetype.RDP", comment: "")
            case .WRP: attr = NSLocalizedString("filetype.WRP", comment: "")
            case .BAD: attr = NSLocalizedString("filetype.BAD", comment: "")
            }
            cell.textField?.stringValue = attr
        case "size"?:
            let size = files[row].size
            cell.textField?.stringValue = "\(size)"
        default: assertionFailure("Unknown column: \(String(describing: tableColumn))")
        }
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        dumpFileButton.isEnabled = table.selectedRow != -1
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let dialogue = NSOpenPanel()
        dialogue.allowsMultipleSelection = false
        dialogue.canChooseDirectories = false
        dialogue.allowedFileTypes = ["d88","d77","d20"]
        guard dialogue.runModal() == NSApplication.ModalResponse.OK, let url = dialogue.url else { return }
        textField.stringValue = url.lastPathComponent
        guard let imgdata = try? Data(contentsOf: url) else { return }
        diskimage = D88Image(data: imgdata)
        files = diskimage!.getFiles()
        table.reloadData()
        
    }
    
    @IBAction func didPressDumpContents(_ sender: Any) {
        guard let fileurl = fileurl else {return}
        let filename = fileurl.deletingPathExtension().appendingPathExtension("2d").lastPathComponent
        print(#function,filename)
        let savepanel = NSSavePanel()
        savepanel.title = NSLocalizedString("Save raw contents of disk", comment: "")
        savepanel.nameFieldStringValue = filename
        guard savepanel.runModal() == NSApplication.ModalResponse.OK,
            let url = savepanel.url else { return }
        let data = diskimage?.rawData
        do {
            try data?.write(to: url)
        }
        catch {
            print(error)
            presentError(error)
        }
    }
    
    @IBAction func didPressDumpFile(_ sender: Any) {
        guard table.selectedRow > -1 else {
            return print(#function, "No file selected")
        }
        let file = files[table.selectedRow]
        print(#function, file.name)
        let dialogue = NSSavePanel()
        dialogue.title = NSLocalizedString("Save file from disk image", comment: "")
        dialogue.nameFieldStringValue = file.name
        guard
            dialogue.runModal() == NSApplication.ModalResponse.OK,
            let url = dialogue.url
            else {
                return
        }
        writeFile(file, to: url)
    }
    
    private func writeFile(_ file: D88Image.FileEntry, to url: URL) {
        let filedata = diskimage?.getFile(file: file)
        do {
            try filedata?.write(to: url)
            print("Saved file to \(url)")
        }
        catch {
            print(error)
            presentError(error)
        }
    }
    
    @objc func didDoubleClickRow() {
        print(#function, table.clickedRow)
        let file = files[table.clickedRow]
        /*
         let filename = file.name
         let tempfile = NSTemporaryDirectory() + filename
        writeFile(file, to: URL(fileURLWithPath: tempfile))
        NSWorkspace.shared().openFile(tempfile, withApplication: "iHex")
         */
        guard file.attributes == .BAS else {
            print("Not a BASIC file")
            return
        }
        guard let filedata = diskimage?.getFile(file: file) else { return }
        let text = N88basic.parse(imgdata: filedata)
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Basic viewer")) as! N88BasicViewController
        self.presentViewControllerAsModalWindow(vc)
        vc.textView.textStorage?.font = NSFont(name: "Monaco", size: 11)
        vc.textView.string = text
        vc.title = file.name
    }
}

