//
//  FileTVController.swift
//  Infoto
//
//  Created by Scott Bridgman on 12/16/15.
//  Copyright © 2015 Tohism. All rights reserved.
//

import UIKit
import CoreData
import AVKit
import AVFoundation
import EasyTipView

class FileTVController: BaseTVC, NSFetchedResultsControllerDelegate, EasyTipViewDelegate {
    
    var folder        : Folders!
    var currView      : FilesView!
    var useDateFormat : Bool!
    var sortDate      : String! = "create_date"
    var lastDeletePrompt : NSTimeInterval = 0
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let frc = NSFetchedResultsController(
            fetchRequest: self.getFileFetchRequest(),
            managedObjectContext: self.moc,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //// DESIGN
        self.view.backgroundColor = VC_BG_COLOR
        
        //// Folder must exist to load this TVC
        if (self.folder == nil) {
            print("Error: Folder was not established")
            self.navigationController?.popViewControllerAnimated(false)
        }

        self.navigationItem.title = self.folder.valueForKey("name") as? String
        
        self.frcFetch()

        if let num = NSUserDefaults.standardUserDefaults().objectForKey("\(self.folder.name)_filesView") as? Int {
            currView = FilesView(rawValue: num)
        }else {
            currView = FilesView.Medium
            NSUserDefaults.standardUserDefaults().setObject(currView.rawValue, forKey: "\(self.folder.name)_filesView")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        if let udf = NSUserDefaults.standardUserDefaults().objectForKey("\(self.folder.name)_useDateFormat") as? Bool {
            useDateFormat = udf
        }else {
            useDateFormat = true
            NSUserDefaults.standardUserDefaults().setObject(useDateFormat, forKey: "\(self.folder.name)_useDateFormat")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        //self.tableView.reloadData()
        
        //// Debug Statements
        //printFiles()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if fetchedResultsController.fetchedObjects!.count == 0 {
            showPopupMessage("No files found.\nTap '+' to add new file.", remove:false)
        } else {
            showTips()
        }
    }
    
    func showTips(){
        
        for tip in activeTips {
            if tip.hasPrefix("file") && !tipIsOpen {
                
                let prefs = getTipPreferences()
                
                guard let cell1 = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? FileCell else {
                    return
                }
                
                switch (tip){
                    
                case "file_1":
                    EasyTipView.show(forView: cell1,
                        withinSuperview: self.tableView,
                        text: "Every file contains a title, date, description and the photo/video.",
                        preferences: prefs,
                        delegate: self)
                    
                case "file_2":
                    EasyTipView.show(forView: cell1.dateLabel,
                        withinSuperview: self.tableView,
                        text: "Tap on date to change its format.",
                        preferences: prefs,
                        delegate: self)
                    
                case "file_3":
                    EasyTipView.show(forView: cell1.dataScrollView,
                        withinSuperview: self.tableView,
                        text: "You can zoom in on photos by double tapping or pinching.",
                        preferences: prefs,
                        delegate: self)
                    
                case "file_4":
                    EasyTipView.show(forItem: self.navigationItem.rightBarButtonItems![2],
                        withinSuperview: self.navigationController!.view,
                        text: "Change sorting",
                        preferences: prefs,
                        delegate: self)
                    
                case "file_5":
                    EasyTipView.show(forItem: self.navigationItem.rightBarButtonItems![1],
                        withinSuperview: self.navigationController!.view,
                        text: "Change the view size.",
                        preferences: prefs,
                        delegate: self)
                    
                case "file_6":
                    EasyTipView.show(forView: cell1,
                        withinSuperview: self.tableView,
                        text: "Tap the cell to view the file.",
                        preferences: prefs,
                        delegate: self)
                    
                default:
                    snp()
                    return
                }
                
                tipIsOpen = true
                activeTips = activeTips.filter({$0 != tip})
                break
            }
        }
        
    }
    
    func easyTipViewDidDismiss(tipView : EasyTipView){
        tipIsOpen = false
        showTips()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: FileCell = tableView.dequeueReusableCellWithIdentifier("FileCell", forIndexPath: indexPath) as! FileCell
        
        cell.file              = fetchedResultsController.objectAtIndexPath(indexPath) as! Files
        cell.titleLabel.text   = (cell.file.title == "") ? "  " : cell.file.title
        cell.descTextView.text = cell.file.desc
        cell.dataScrollView.viewWithTag(20)?.removeFromSuperview()
        
        //// Add dateLabel text
        let date = (sortDate == "create_date") ? cell.file.create_date : cell.file.edit_date
        cell.dateLabel.text = getFileDateLabelText(date, useDateFormat: useDateFormat)
        
        //// Add recognizer to dateLabel
        let dateTap = UITapGestureRecognizer(target: self, action: #selector(FileTVController.dateLabelTapped))
        dateTap.numberOfTapsRequired = 1
        cell.dateLabel.addGestureRecognizer(dateTap)
        
        let dataTappedOnceGest = UITapGestureRecognizer(target: self, action: #selector(FileTVController.dataTappedTwice(_:)))
        dataTappedOnceGest.numberOfTapsRequired = 2
        cell.dataScrollView.addGestureRecognizer(dataTappedOnceGest)
        
        //// Remove and re-add width constraint from dataScrollView based in currView
        for c in cell.constraints{
            if (c.identifier == "dataScrollViewWidth"){
                c.active = false
            }
        }
        
        let mult:CGFloat!
        switch (currView!){
            case .Small:
                mult = 0.15
                cell.titleDateStackView.axis      = .Horizontal
                cell.titleDateStackView.alignment = .Center
                cell.titleLabel.font     = UIFont (name: "Helvetica Neue", size: 20)
                cell.descTextView.hidden = true
                cell.dateLabel.hidden    = false
            case .Medium:
                mult = 0.5
                cell.titleDateStackView.axis      = .Vertical
                cell.titleDateStackView.alignment = .Trailing
                cell.titleLabel.font     = UIFont(name: "Helvetica Neue", size: 18)
                cell.descTextView.hidden = false
                cell.dateLabel.hidden    = false
                if cell.descTextView.text == "" {
                    cell.descTextView.backgroundColor = UIColor.clearColor()
                } else {
                    cell.descTextView.backgroundColor = VC_FG_COLOR
                }
            case .Large:
                mult = 0.95
                cell.titleLabel.text   = ""
                cell.descTextView.text = ""
                cell.descTextView.hidden = true
                cell.dateLabel.hidden    = true
        }
        
        if (cell.descTextView.text == "" || currView! != .Medium) {
            cell.descTextView.scrollEnabled          = false
            cell.descTextView.userInteractionEnabled = false
        } else {
            cell.descTextView.scrollEnabled          = true
            cell.descTextView.userInteractionEnabled = true
        }
        
        let aspectRatioConstraint = NSLayoutConstraint(item: cell.dataScrollView,
            attribute: NSLayoutAttribute.Width,
            relatedBy: NSLayoutRelation.Equal,
            toItem: cell,
            attribute: NSLayoutAttribute.Width,
            multiplier: mult,
            constant: 0)
        aspectRatioConstraint.identifier = "dataScrollViewWidth"
        cell.addConstraint(aspectRatioConstraint)
        cell.layoutIfNeeded()
        
        if let fileName = cell.file.fileName {
        
            if cell.file.fileType == "Photo"{
                
                if let image = UIImage(contentsOfFile: getFilePath(fileName)){
                    cell.configureImageView(image, currView:currView)
                }
                
            } else {
                
                cell.dataScrollView.userInteractionEnabled = true
                cell.dataImageView.hidden                  = true
                let url           = NSURL(fileURLWithPath: getFilePath(fileName))
                let avPlayerVC    = AVPlayerViewController()
                let player        = AVPlayer(URL: url)
                avPlayerVC.player = player
                self.addChildViewController(avPlayerVC)
                avPlayerVC.view.frame = CGRectMake(0,0,cell.dataScrollView.bounds.width, cell.dataScrollView.bounds.height)
                avPlayerVC.view.tag   = 20
                cell.dataScrollView.addSubview(avPlayerVC.view)
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("file2display", sender: indexPath)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // the cells you would like the actions to appear needs to be editable
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // need to invoke this method to have editActions work. No code needed.
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let editAction = UITableViewRowAction(style: .Normal, title: "  Edit  ") { action, index in
            self.performSegueWithIdentifier("file2editFile", sender: indexPath)
        }
        
        editAction.backgroundColor = UIColor.blueColor()
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
            
            if NSDate().timeIntervalSinceReferenceDate - self.lastDeletePrompt > 60 {
            
                let actionSheetController: UIAlertController = UIAlertController(title: "Delete File?", message: "You will not get prompted if you delete other files.", preferredStyle: .Alert)
                let noAction: UIAlertAction     = UIAlertAction(title: "Nope", style: .Default) { action -> Void in }
                let deleteAction: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action -> Void in
                    
                    self.lastDeletePrompt = NSDate().timeIntervalSinceReferenceDate
                    let fileToDelete = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Files
                    self.deleteFile(fileToDelete)

                }
                actionSheetController.addAction(noAction)
                actionSheetController.addAction(deleteAction)
                self.presentViewController(actionSheetController, animated: true, completion: nil)
            } else {
                self.lastDeletePrompt = NSDate().timeIntervalSinceReferenceDate
                let fileToDelete = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Files
                self.deleteFile(fileToDelete)
            }
        }
        
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [editAction, deleteAction]
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let file = fetchedResultsController.objectAtIndexPath(indexPath) as! Files

        let mult:CGFloat!
        var aspectRatio:CGFloat = 1.0
        
        if file.fileType == "Photo" {
            if let img = UIImage(contentsOfFile: getFilePath(file.fileName!)){
                aspectRatio = img.size.height / img.size.width
            }
        }else{ /// VIDEO
            aspectRatio = 1.5
        }
        
        switch (currView!){
            case .Small:
                mult        = 0.15
                aspectRatio = 1.0
            case .Medium:
                mult = 0.5
            case .Large:
                mult = 0.95
        }
        
        return self.view.bounds.width * aspectRatio * mult
    }
    
    // MARK: - IBActions
    
    @IBAction func changeSort(sender: AnyObject) {
        
        self.folder.sortBy = (self.folder.sortBy + 1) % 4
        self.saveContext()
        self.fetchedResultsController.setValue(self.getFileFetchRequest(), forKey:"fetchRequest")
        self.frcFetch()
        self.tableView.reloadData()
        self.showPopupMessage("Sorted by:\n\(getSortName(SortBy(rawValue:folder.sortBy)!))")
    }
    
    @IBAction func changeView(sender: AnyObject) {
        let newNum = (currView.rawValue + 1) % 3
        currView = FilesView(rawValue: newNum)
        NSUserDefaults.standardUserDefaults().setObject(currView.rawValue, forKey: "\(self.folder.name)_filesView")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.tableView.reloadData()
    }
    
    @IBAction func newFile(sender: AnyObject) {
        
        presentNewFileOptions("file")
        
    }
    
    // MARK: - Other Methods
    
    func dateLabelTapped(){
        useDateFormat = !useDateFormat
        NSUserDefaults.standardUserDefaults().setObject(useDateFormat, forKey: "\(self.folder.name)_useDateFormat")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.tableView.reloadData()
    }
    
    func dataTappedTwice(gesture: UITapGestureRecognizer){
        if let cell = gesture.view?.superview?.superview as? FileCell {
            let indexPath = self.tableView.indexPathForCell(cell)
            self.performSegueWithIdentifier("file2display", sender: indexPath)
        } else {
            snp()
        }
    }
    
    func getFileFetchRequest() -> NSFetchRequest {
        let filesFetchRequest = NSFetchRequest(entityName: "Files")
        filesFetchRequest.predicate = NSPredicate(format: "whichFolder == %@", self.folder)
        
        var sortOrder = "recent"
        
        switch (SortBy(rawValue: self.folder.sortBy)!){
            case .CreateRecent:
                sortDate  = "create_date"
                sortOrder = "recent"
            case .CreateOldest:
                sortDate  = "create_date"
                sortOrder = "oldest"
            case .EditRecent:
                sortDate  = "edit_date"
                sortOrder = "recent"
            case .EditOldest:
                sortDate  = "edit_date"
                sortOrder = "oldest"
        }
        
        let primarySortDescriptor = NSSortDescriptor(key: sortDate, ascending: ((sortOrder == "recent") ? false : true))
        //let secondarySortDescriptor = NSSortDescriptor(key: "commonName", ascending: true)
        filesFetchRequest.sortDescriptors = [primarySortDescriptor]
        return filesFetchRequest
    }
    
    func frcFetch(){
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred: \(error)")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == "file2display") {
            let dvc = segue.destinationViewController as! DisplayViewController
            let indexPath:NSIndexPath = sender as! NSIndexPath
            dvc.file = fetchedResultsController.objectAtIndexPath(indexPath) as! Files
            return
        }
        
        let dvc = segue.destinationViewController as! NewFileViewController
        dvc.folder   = self.folder
        
        if (segue.identifier == "file2newFile"){
            
            self.setNewFileDVC(dvc, sender:sender)
            
        } else if (segue.identifier == "file2editFile") {
            
            let indexPath:NSIndexPath = sender as! NSIndexPath
            let file = fetchedResultsController.objectAtIndexPath(indexPath) as! Files
            dvc.fileType = file.fileType
            dvc.editMode = true
            dvc.editFile = file
        }
    }
    
}






