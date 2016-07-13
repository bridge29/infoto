//
//  NewFolderViewController.swift
//  Infoto
//
//  Created by Scott Bridgman on 12/17/15.
//  Copyright © 2015 Tohism. All rights reserved.
//

import UIKit
import CoreData
import EasyTipView

class NewFolderViewController: BaseVC, UITextFieldDelegate {

    @IBOutlet weak var lockSwitch: UISwitch!
    @IBOutlet weak var folderName: UITextField!
    @IBOutlet weak var lockLabel: UILabel!
    var editMode = false
    var editFolder : Folders!
    var dtdArray = ["Never"]
    var orderPosition:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.folderName.delegate = self
        
        for num in 1...30{
            dtdArray.append("\(num)")
        }
        
        if editMode {
            self.folderName.text = self.editFolder.name
            self.lockSwitch.on   = self.editFolder.isLocked
            self.lockLabel.text = (self.editFolder.isLocked) ? "Locked" : "Unlocked"
        }
        
        let firstWordOfTitle = (editMode) ? "Edit" : "New"
        self.navigationItem.title = "\(firstWordOfTitle) Folder"
    }
    
    // MARK: - Delegate Methods
    
//    func textFieldShouldBeginEditing(textField: UITextField) -> Bool{
//        print("TextField did begin editing method called")
//        return true
//    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    // MARK: - IBActions
    
    //// Toggle lock/unlocked text when user toggles switch
    //// enabled = locked
    @IBAction func switchChanged(sender: UISwitch) {
        self.lockLabel.text = (sender.on) ? "Locked" : "Unlocked"
    }
    
    @IBAction func showQuestionMarkMessage(sender: UIButton) {
        switch (sender.tag) {
            case 11:
                notifyAlert(self, title: "Folder Name", message: "The name of your folder. Give a name that categorizes the infotos (e.g. Recipes).")
            case 12:
                notifyAlert(self, title: "Lock Option", message: "Locked folders can only be accessed using Touch ID. Lock folders for infotos you want to keep private (e.g. passwords).")
            default:
                break
        }
    }
    
    @IBAction func saveFolder(sender: AnyObject) {
        
        let isLocked      = (self.lockLabel.text == "Locked") ? true : false
        var name          = self.folderName.text!
        name              = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        if (name == "") {
            
            notifyAlert(self, title: "Uh oh", message: "Folder must have a name")
            return
            
        } else if (!editMode) {
        
            let fetchRequest = NSFetchRequest(entityName: "Folders")
            fetchRequest.predicate = NSPredicate(format: "name == %@", name)
            
            do {
                let fetchResults = try self.moc.executeFetchRequest(fetchRequest)
                
                if fetchResults.count > 0 {
                    notifyAlert(self, title: "Uh oh", message: "That folder name exists, try another one.")
                } else {
                    
                    //// Folder name is valid, save folder and pop view controller
                    self.createFolder(name, isLocked: isLocked, orderPosition: orderPosition)
                    self.navigationController?.popViewControllerAnimated(true)
                }
            } catch {
                fatalError("Failed fetch request: \(error)")
            }
        } else {
            self.editFolder.name = name
            self.editFolder.isLocked = isLocked
            saveContext()
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func cancelFolder(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }

}
