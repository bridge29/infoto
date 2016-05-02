//
//  FolderTVController.swift
//  Infoto
//
//  Created by Scott Bridgman on 12/15/15.
//  Copyright © 2015 Tohism. All rights reserved.
//

import UIKit
import CoreData
import LocalAuthentication
import EasyTipView

class FolderTVController: BaseTVC, NSFetchedResultsControllerDelegate, EasyTipViewDelegate {
    
    var selectedFolder : Folders!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let foldersFetchRequest   = NSFetchRequest(entityName: "Folders")
        let primarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        //let secondarySortDescriptor = NSSortDescriptor(key: "commonName", ascending: true)
        foldersFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let frc = NSFetchedResultsController(
            fetchRequest: foldersFetchRequest,
            managedObjectContext: self.moc,
            sectionNameKeyPath: "name",
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSUserDefaults.standardUserDefaults().setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        //// DESIGN
        self.view.backgroundColor = VC_BG_COLOR
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        
        //// NESTS FOR TAKING ACTIONS FOR USERS WITH NEW VERSIONS OF THE APP
        if (NSUserDefaults.standardUserDefaults().valueForKey("v1.0") == nil) {
            
            //// CREATE FOLDERS FOR FIRST TIME USERS
            for (name, isLocked, daysTilDelete) in [("Temp",false,7), ("Private",true,0), ("Misc",false,0)] {
                self.createFolder(name, isLocked: isLocked, daysTilDelete:daysTilDelete)
            }
            
            //// CREATE SAMPLE FILES FOR FIRST TIME USERS
            let fileName1 = "\(Int(NSDate().timeIntervalSince1970)).jpg"
            UIImageJPEGRepresentation(UIImage(named: "camera")!,1.0)!.writeToFile(getFilePath(fileName1), atomically: true)
            let newFile1 = NSEntityDescription.insertNewObjectForEntityForName("Files", inManagedObjectContext: self.moc)
            newFile1.setValue("Passport Info", forKey: "title")
            newFile1.setValue("Key Details:\nPassport #:1234567\nIssued:10/10/13\nExpires:10/10/23", forKey: "desc")
            newFile1.setValue(NSDate(), forKey: "create_date")
            newFile1.setValue(NSDate(), forKey: "edit_date")
            newFile1.setValue(fileName1, forKey: "fileName")
            newFile1.setValue("Photo", forKey: "fileType")
            newFile1.setValue(fetchedResultsController.fetchedObjects?.last, forKey: "whichFolder")
            
            let fileName2 = "\(Int(NSDate().timeIntervalSince1970) + 1).jpg"
            UIImageJPEGRepresentation(UIImage(named: "camera")!,1.0)!.writeToFile(getFilePath(fileName2), atomically: true)
            let newFile2 = NSEntityDescription.insertNewObjectForEntityForName("Files", inManagedObjectContext: self.moc)
            newFile2.setValue("Passport Info", forKey: "title")
            newFile2.setValue("This is an example file\n\nKey Details:\nPassport #:1234567\nIssued:10/10/13\nExpires:10/10/23", forKey: "desc")
            newFile2.setValue(NSDate(), forKey: "create_date")
            newFile2.setValue(NSDate(), forKey: "edit_date")
            newFile2.setValue(fileName2, forKey: "fileName")
            newFile2.setValue("Photo", forKey: "fileType")
            newFile2.setValue(fetchedResultsController.fetchedObjects?.last, forKey: "whichFolder")
            saveContext()

            NSUserDefaults.standardUserDefaults().setInteger(1, forKey: "v1.0")
            NSUserDefaults.standardUserDefaults().synchronize()
            
        }
        
        if rateNumber > 0 {
            rateNumber = rateNumber + 1
        }
        
        ///// DEBUGGING
        //printFileContents()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        for folder in fetchedResultsController.fetchedObjects as! [Folders]{
            self.deleteTempFiles(folder)
        }
        
        if rateNumber > MAX_RATE_HITS {
            showRateUs()
        }
        
        showTips()
        
        if activeTips.count == 1 {
            showPopupMessage("No More Tips\nYou're ready to rock!")
            activeTips = []
        }
        
        /// TESTING: Menu
        //performSegueWithIdentifier("folder2menu", sender: nil)
        
    }
    
    func showTips(){
                
        for tip in activeTips {
            if tip.hasPrefix("folder") && !tipIsOpen {
                
                guard let cell2 = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? FolderTVCell else {
                    return
                }
                
                let prefs = getTipPreferences()
                
                switch (tip){
                    
                    case "folder_1":
                        EasyTipView.show(forView: cell2.titleLabel,
                            withinSuperview: self.tableView,
                            text: "These are your folders that hold your files. Swipe left to edit/delete them.",
                            preferences: prefs,
                            delegate: self)
                    
                    case "folder_2":
                        EasyTipView.show(forView: cell2.cameraIMG,
                            withinSuperview: self.tableView,
                            text: "Create a file.",
                            preferences: prefs,
                            delegate: self)
                    
                    case "folder_3":
                        //let cell1 = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! FolderTVCell
                        EasyTipView.show(forView: cell2.lockIMG,
                            withinSuperview: self.tableView,
                            text: "You can lock folders. Locked folders can only be accessed by Touch ID.",
                            preferences: prefs,
                            delegate: self)
                    
                    case "folder_4":
                        EasyTipView.show(forItem: self.navigationItem.rightBarButtonItem!,
                            withinSuperview: self.navigationController!.view,
                            text: "Create a new folder",
                            preferences: prefs,
                            delegate: self)

                    default:
                        return
                }
                
                tipIsOpen = true
                activeTips.removeAtIndex(0)
                break
            }
        }
    }
    
    func easyTipViewDidDismiss(tipView : EasyTipView){
        tipIsOpen = false
        showTips()
        if !tipIsOpen {
            
            if let objects = fetchedResultsController.fetchedObjects {
                if objects.count >= 3{
                    self.showPopupMessage("Let's take a look inside a folder...", remove:false)
                    _ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.goToFileFromTips), userInfo: nil, repeats: false)
                }
            }
        }
    }
    
    func goToFileFromTips() {
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as! FolderTVCell
        performSegueWithIdentifier("folder2file", sender: cell)

    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let objects = fetchedResultsController.fetchedObjects {
            return max(1,objects.count)
        }
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: FolderTVCell = tableView.dequeueReusableCellWithIdentifier("FolderCell", forIndexPath: indexPath) as! FolderTVCell
        cell.folder            = fetchedResultsController.objectAtIndexPath(indexPath) as! Folders
        cell.titleLabel.text   = (cell.folder.daysTilDelete == 0) ? cell.folder.name : "\(cell.folder.name!) - \(cell.folder.daysTilDelete)"
        
        if cell.folder.isLocked {
            cell.lockIMG.hidden = false
        } else {
            cell.lockIMG.hidden = true
        }
        
        let tapGest1 = UITapGestureRecognizer(target: self, action: #selector(FolderTVController.cellActionTapped(_:)))
        tapGest1.numberOfTapsRequired = 1
        cell.cameraIMG.addGestureRecognizer(tapGest1)
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        checkAuthAndSegue(indexPath)
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }
    
    func cellActionTapped(gesture:UIGestureRecognizer){
        
        let location : CGPoint = gesture.locationInView(self.tableView)
        let cellIndexPath:NSIndexPath = self.tableView.indexPathForRowAtPoint(location)!
        let cell = self.tableView.cellForRowAtIndexPath(cellIndexPath) as! FolderTVCell
        
        selectedFolder = cell.folder as Folders
        presentNewFileOptions("folder")
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
            self.checkAuthAndSegue(indexPath, segueToFile: false)
        }
        editAction.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 255/255, alpha: 1)
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
            
            let folder = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Folders
            let fetchRequest = NSFetchRequest(entityName: "Files")
            fetchRequest.predicate = NSPredicate(format: "whichFolder == %@", folder)
            
            do {
                let fetchResults = try self.moc.executeFetchRequest(fetchRequest)
                if fetchResults.count > 0 {
                    
                    let actionSheetController1: UIAlertController = UIAlertController(title: "Delete", message: "This folder contains files which will be deleted. Are sure you want to delete the \"\(folder.name!)\" folder?", preferredStyle: .Alert)
                    let noAction1: UIAlertAction     = UIAlertAction(title: "Nope", style: .Default) { action -> Void in }
                    let deleteAction1: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action -> Void in
                        
                        let actionSheetController2: UIAlertController = UIAlertController(title: "Final Delete Check", message: "One last time, are you sure you want to delete this folder?", preferredStyle: .Alert)
                        let noAction2: UIAlertAction     = UIAlertAction(title: "Nope", style: .Default) { action -> Void in }
                        let deleteAction2: UIAlertAction = UIAlertAction(title: "DELETE IT!", style: .Default) { action -> Void in
                            self.deleteFolder(folder)
                        }
                        
                        actionSheetController2.addAction(noAction2)
                        actionSheetController2.addAction(deleteAction2)
                        self.presentViewController(actionSheetController2, animated: true, completion: nil)
                        
                    }
                    
                    actionSheetController1.addAction(noAction1)
                    actionSheetController1.addAction(deleteAction1)
                    self.presentViewController(actionSheetController1, animated: true, completion: nil)
                    
                } else {
                    self.deleteFolder(folder)
                }
            } catch {
                fatalError("Failed fetch request: \(error)")
            }
        }
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [editAction, deleteAction]
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clearColor()
        return headerView;
    }
    
    // MARK: - IBActions
    
    // MARK: - Other Methods
    
    func showRateUs() {
        let alert = UIAlertController(title: "Rate Us!", message: "If you like \(APP_NAME), we'd love to hear it. Your rating really helps us get noticed in the App Store. If you hate it then you're in luck, you can skip this ;)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Rate \(APP_NAME)", style: UIAlertActionStyle.Default, handler: { alertAction in
            //UIApplication.sharedApplication().openURL(NSURL(string : "LINK_GOES_HERE")!)
            rateNumber = 0
        }))
        alert.addAction(UIAlertAction(title: "No Thanks", style: UIAlertActionStyle.Default, handler: { alertAction in
            rateNumber = 0
        }))
        alert.addAction(UIAlertAction(title: "Maybe Later", style: UIAlertActionStyle.Default, handler: { alertAction in
            rateNumber = 1
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func deleteFolder(folderToDelete:Folders){
        
        /// Delete All Files in Folder
        let fetchRequest = NSFetchRequest(entityName: "Files")
        fetchRequest.predicate = NSPredicate(format: "whichFolder == %@", folderToDelete)
        
        do {
            let fetchResults = try self.moc.executeFetchRequest(fetchRequest) as! [Files]
            for file in fetchResults {
                // must also delete the file itself 
                self.deleteFile(file)
                
            }
        } catch {
            fatalError("Failed fetch request: \(error)")
        }
        
        /// Delete Folder
        self.moc.deleteObject(folderToDelete)
        self.saveContext()
    }
    
    func checkAuthAndSegue(indexPath:NSIndexPath, segueToFile:Bool=true) {
        
        let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! FolderTVCell
        
        if cell.folder.isLocked {
            let authenticationContext = LAContext()
            var error:NSError?
            guard authenticationContext.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) else {
                notifyAlert(self, title: "Sorry", message: "Touch ID was not detected on your phone.")
                return
            }
            
            authenticationContext.evaluatePolicy(
                .DeviceOwnerAuthenticationWithBiometrics,
                localizedReason: "User Touch ID to view \(cell.folder.name!) folder",
                reply: {(success, error) -> Void in
                    
                    if( success ) {
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            if segueToFile {
                                self.performSegueWithIdentifier("folder2file", sender: cell)
                            } else {
                                self.performSegueWithIdentifier("folder2newFolder", sender: indexPath)
                            }
                        })
                        
                    } else {
                        
                        switch error!.code {
                            //case LAError.SystemCancel.rawValue:
                            //print("Authentication cancelled by the system")
                            //case LAError.UserCancel.rawValue:
                        //print("Authentication cancelled by the user")
                        case LAError.UserFallback.rawValue:
                            //print("User wants to use a password")
                            // We show the alert view in the main thread (always update the UI in the main thread)
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                notifyAlert(self, title: "Sorry", message: "Only Touch ID can open locked folders.")
                            })
                        default:
                            break
                            //print("Authentication failed")
                        }
                        
                    }
                    
            })
            
        }else {
            if segueToFile {
                self.performSegueWithIdentifier("folder2file", sender: cell)
            } else {
                self.performSegueWithIdentifier("folder2newFolder", sender: indexPath)
            }
        }
    }
    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier! {
            
            case "folder2file":
                let dvc = segue.destinationViewController as! FileTVController
                let cell = sender as! FolderTVCell
                dvc.folder = cell.folder
            
            case "folder2newFile":
                let dvc = segue.destinationViewController as! NewFileViewController
                dvc.folder = selectedFolder
                setNewFileDVC(dvc, sender: sender)
            
            case "folder2newFolder":
                let dvc = segue.destinationViewController as! NewFolderViewController
                if (object_getClass(sender).description() == "NSIndexPath"){
                    let indexPath  = sender as! NSIndexPath
                    dvc.editFolder = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Folders
                    dvc.editMode   = true
                }
            default:
                break
        }
    }

}
