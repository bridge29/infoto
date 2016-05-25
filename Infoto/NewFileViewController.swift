//
//  NewFileViewController.swift
//  Infoto
//
//  Created by Scott Bridgman on 12/18/15.
//  Copyright © 2015 Tohism. All rights reserved.
//
// Important Tags:
//  10: CoverView

import UIKit
import CoreData
import AVFoundation
import AVKit
import MobileCoreServices
import AssetsLibrary

class NewFileViewController: BaseVC, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var folderView: UIPickerView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dataView: UIView!
    @IBOutlet weak var cameraRollButton: UIButton!
    
    var folder      : Folders!
    var folders     : [Folders] = []
    var fileType    : String!
    var fileImage   : UIImage!
    var editFile    : Files!
    var avPlayerVC  : AVPlayerViewController!
    var urlVideo    : NSURL!
    var hasFileInfo = false
    var editMode    = false
    var firstAction = ""
    var isTextMode  = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = VC_BG_COLOR
        
        let firstWordOfTitle = (editMode) ? "Edit" : "New"
        self.navigationItem.title = "\(firstWordOfTitle) \(fileType)"
        self.titleTextField.text  = (editMode) ? self.editFile.title : PRE_TITLE_TEXT
        self.descTextView.text    = (editMode) ? self.editFile.desc  : PRE_DESC_TEXT
        self.titleTextField.delegate = self
        self.descTextView.delegate   = self
        self.folderView.delegate     = self
        
        
        /// Setup for photo or video
        switch (fileType){
            case "Photo":
                self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
            case "Video":
                self.cameraRollButton.setTitle("Videos", forState: UIControlState.Normal)
                self.imageView.hidden = true
                self.avPlayerVC       = AVPlayerViewController()
                self.addChildViewController(self.avPlayerVC)
                self.avPlayerVC.view.frame = CGRectMake(0,0,self.dataView.bounds.width,self.dataView.bounds.height)
                self.dataView.addSubview(self.avPlayerVC.view)
            default:
                break
        }
        
        /// Fetch folders to populate folder picker view
        let fetchRequest = NSFetchRequest(entityName: "Folders")
        do {
            let fetchedFolders = try self.moc.executeFetchRequest(fetchRequest) as! [Folders]
            folders.append(self.folder)
            for f in fetchedFolders {
                if f.name != self.folder.name {
                    folders.append(f)
                }
            }
        } catch {
            fatalError("Failed fetch request: \(error)")
        }
        
        /// Hide Picker lines
        
        /// Hack to show white screen in transition to ImagePicker view.
        /// View will get removed when the ImagePicker view is popped
        if (self.firstAction != "") {
            let coverView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: view.bounds.size))
            coverView.tag = 10
            coverView.backgroundColor = UIColor.whiteColor()
            view.addSubview(coverView)
        }
        
        if (editMode){
            
            switch (fileType){
                case "Photo":
                    self.fileImage       = UIImage(contentsOfFile: getFilePath(self.editFile.fileName!))
                    self.imageView.image = self.fileImage
                case "Video":
                    self.urlVideo = NSURL(fileURLWithPath: getFilePath(self.editFile.fileName!))
                    let player    = AVPlayer(URL: self.urlVideo)
                    self.avPlayerVC.player = player
                default:
                    break
            }
        } else {
            
            if self.firstAction == "take" {
                getFileData(true)
            } else if self.firstAction == "choose" {
                getFileData(false)
            }
            self.firstAction = ""
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return folders.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let folder = folders[row]
        return folder.name
    }
    
    func getFileData(useCamera:Bool){
        
        if fileType == "Photo"{
        
            let imagePickCont        = UIImagePickerController()
            imagePickCont.delegate   = self
            imagePickCont.sourceType = useCamera ? UIImagePickerControllerSourceType.Camera : UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(imagePickCont, animated: true, completion: nil)
            
        } else if fileType == "Video" {
            
            let ipcVideo              = UIImagePickerController()
            ipcVideo.delegate         = self
            ipcVideo.sourceType       = useCamera ? UIImagePickerControllerSourceType.Camera : UIImagePickerControllerSourceType.PhotoLibrary
            let kUTTypeMovieAnyObject = kUTTypeMovie as AnyObject
            ipcVideo.mediaTypes       = [kUTTypeMovieAnyObject as! String]
            self.presentViewController(ipcVideo, animated: true, completion: nil)
        }
    }
    
    // MARK: - Delegate Methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        animateTextField(false)
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if (textField.text == PRE_TITLE_TEXT){
            textField.text = ""
        }
        animateTextField(true)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (textView.text == PRE_DESC_TEXT) {
            textView.text = ""
        }
        animateTextField(true)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        textView.resignFirstResponder()
        animateTextField(false)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.view.viewWithTag(10)?.removeFromSuperview()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if self.fileType == "Video" {
            self.urlVideo = info[UIImagePickerControllerMediaURL] as! NSURL
            self.dismissViewControllerAnimated(true, completion: nil)
            let player             = AVPlayer(URL: self.urlVideo)
            self.avPlayerVC.player = player

        } else if self.fileType == "Photo" {
            self.fileImage       = info[UIImagePickerControllerOriginalImage] as! UIImage
            self.imageView.image = self.fileImage
        }
        self.view.viewWithTag(10)?.removeFromSuperview()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func takeButtonPushed(sender: AnyObject) {
        getFileData(true)
    }
    
    
    @IBAction func chooseButtonPressed(sender: AnyObject) {
        getFileData(false)
    }
    
    
    @IBAction func saveFile(sender: AnyObject) {
        
        var title    = self.titleTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var desc     = self.descTextView.text!
        title        = (title == PRE_TITLE_TEXT) ? "" : title
        title        = (title == "") ? "No Title" : title
        desc         = (desc  == PRE_DESC_TEXT)  ? "" : desc
        let fileExt  = (fileType == "Photo") ? "jpg" : "mov"
        let fileName = (editMode) ? self.editFile.fileName! : "\(Int(NSDate().timeIntervalSince1970)).\(fileExt)"
        
        if (saveData(fileName)){
            
            if (editMode){
                
                self.editFile.edit_date = NSDate.timeIntervalSinceReferenceDate()
                self.editFile.title = title
                self.editFile.desc  = desc
                self.editFile.whichFolder = self.folders[folderView.selectedRowInComponent(0)]
                
            } else {
                
                let newFile = NSEntityDescription.insertNewObjectForEntityForName("Files", inManagedObjectContext: self.moc)
                newFile.setValue(fileType, forKey: "fileType")
                newFile.setValue(title, forKey: "title")
                newFile.setValue(desc, forKey: "desc")
                newFile.setValue(NSDate(), forKey: "create_date")
                newFile.setValue(NSDate(), forKey: "edit_date")
                newFile.setValue(fileName, forKey: "fileName")
                newFile.setValue(self.folders[folderView.selectedRowInComponent(0)], forKey: "whichFolder")
            }
            
            saveContext()

        }else {
            
            notifyAlert(self, title: "Uh Oh", message: "\(fileType) was not saved. Take a \(fileType) or select one from your Camera Roll.")
            return
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func cancelFile(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - Other Methods
    
    func animateTextField(up: Bool) {
        
        if (up && isTextMode) { return }
        isTextMode = up
        
        var upNum:CGFloat
        switch (self.view.bounds.height) {
            case 0..<300.0:
                upNum = 400
            case 300..<500:
                upNum = 300
            default:
                upNum = 250
        }
        
        let movement:CGFloat = (up ? -upNum : upNum)
        
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame = CGRectOffset(self.view.frame, 0, movement)
        })
    }
    
    func saveData(fileName:String) -> Bool{
        
        switch fileType {
            case "Photo":
                if let image = self.imageView.image {
                    UIImageJPEGRepresentation(image,1.0)!.writeToFile(getFilePath(fileName), atomically: true)
                    return true
                }
            case "Video":
                if let url = self.urlVideo {
                    let newFileURL = NSURL(fileURLWithPath: getFilePath(fileName))
                    let videoData = NSData(contentsOfURL: url)
                    videoData?.writeToURL(newFileURL, atomically: true)
                    return true
                }
            default:
                break
        }
        return false
    }

}

//// Keep in portrait mode
//extension UINavigationController {
//    public override func shouldAutorotate() -> Bool {
//        
//        if visibleViewController is NewFileViewController {
//            return false
//        }
//        return true
//    }
//    
//    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
//        
//        if visibleViewController is NewFileViewController {
//            return UIInterfaceOrientationMask.Portrait
//        }
//        return UIInterfaceOrientationMask.All
//    }
//}

