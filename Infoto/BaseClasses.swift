//
//  BaseClasses.swift
//  Infoto
//
//  Created by Scott Bridgman on 12/17/15.
//  Copyright © 2015 Tohism. All rights reserved.
//

import UIKit
import CoreData
import SwiftyStoreKit


class BaseVC: UIViewController {
    
    var moc: NSManagedObjectContext!
    var tipIsOpen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.moc = appDel.managedObjectContext
    }
    
    //// Creates folder item in core data
    func createFolder(name:String, isLocked:Bool, orderPosition:Int = 0){
        
        //// Make fetch request to check if folder already exists.
        //// Can't have two folders with same name.
        
        let fetchRequest = NSFetchRequest(entityName: "Folders")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let fetchResults = try self.moc.executeFetchRequest(fetchRequest)
            if fetchResults.count > 0 {
                print("\(name) exists!")
                return
            }
        } catch {
            snp()
            //fatalError("Failed fetch request: \(error)")
        }
        
        let newFolder = NSEntityDescription.insertNewObjectForEntityForName("Folders", inManagedObjectContext: self.moc)
        newFolder.setValue(name, forKey: "name")
        newFolder.setValue(isLocked, forKey: "isLocked")
        newFolder.setValue(orderPosition, forKey: "orderPosition")
        saveContext()
    }
    
    func saveContext(){
        do {
            try self.moc.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    func showPopupMessage(message:String, seconds:NSTimeInterval = 2.5, widthMult:CGFloat = 0.9, heightMult:CGFloat = 1.0, remove:Bool = true){
        if let superview = self.view.superview {
            while let view = superview.viewWithTag(101) {
                view.removeFromSuperview()
            }
        }else{
            snp()
            return
        }
        
        let heightSize  = CGFloat((Double(message.characters.count) / 50.0) * 30.0) * heightMult
        let mainView    = self.view.superview!
        let labelWidth  = mainView.bounds.width * widthMult
        let label = UILabel(frame: CGRect(x: (mainView.bounds.width - labelWidth)/2, y: (mainView.bounds.height - heightSize)/2, width: labelWidth, height: 60 + heightSize))
        label.text               = message
        label.tag                = 101
        label.textColor          = UIColor.whiteColor()
        label.backgroundColor    = PU_BG_COLOR
        label.textAlignment      = .Center
        label.lineBreakMode      = .ByWordWrapping
        label.numberOfLines      = 20
        label.minimumScaleFactor = 0.5
        label.font               = UIFont(name: "Futura-Medium", size: 17)
        label.adjustsFontSizeToFitWidth = true
        
        let padding = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        let wrapperView:UIView = label.withPadding(padding)
        wrapperView.frame = label.frame
        wrapperView.tag                = 101
        wrapperView.backgroundColor    = PU_BG_COLOR
        wrapperView.layer.cornerRadius = 20.0
        wrapperView.clipsToBounds      = true
        //wrapperView.sizeToFit()
        mainView.addSubview(wrapperView)
        
        label.userInteractionEnabled = true
        let gest = UITapGestureRecognizer(target: self, action: #selector(BaseTVC.removePopup))
        gest.numberOfTapsRequired = 1
        label.addGestureRecognizer(gest)
        
        if remove {
            _ = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: #selector(BaseTVC.removePopup), userInfo: nil, repeats: false)
        }
    }
    
    func removePopup(){
        if let superview = self.view.superview {
            UIView.animateWithDuration(0.6, animations: {superview.viewWithTag(101)?.alpha = 0.0},
               completion: {(value: Bool) in
                while let view = superview.viewWithTag(101) {
                    ///let label = view as! UILabel
                    ///print (label.text)
                    view.removeFromSuperview()
                }
            })
        }
    }
}

class BaseTVC: UITableViewController {
    
    var moc: NSManagedObjectContext!
    var tipIsOpen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.moc = appDel.managedObjectContext
    }
    
    func setNewFileDVC(dvc:NewFileViewController, sender:AnyObject?){
        
        let action = sender as! UIAlertAction
        let title  = action.title!
        
        if (title.rangeOfString("Take") != nil) {
            dvc.firstAction = "take"
        }else if title.rangeOfString("Choose") != nil {
            dvc.firstAction = "choose"
        }
        
        if (title.rangeOfString("Photo") != nil) {
            dvc.fileType = "Photo"
        }else if (title.rangeOfString("Video") != nil) {
            dvc.fileType = "Video"
        }else {
            dvc.fileType = title
        }
    }
    
    func getIAPInfo() {
        SwiftyStoreKit.retrieveProductsInfo([IAP_ID]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = NSNumberFormatter.localizedStringFromNumber(product.price ?? 0, numberStyle: .CurrencyStyle)
                print("Product: \(product.localizedDescription), price: \(priceString)")
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                return notifyAlert(self, title:"Could not retrieve product info", message: "Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(result.error)")
            }
        }
    }
    
    func purchaseProduct(){
        SwiftyStoreKit.purchaseProduct(IAP_ID) { result in
            switch result {
                case .Success(_):
                    ///print("Purchase Success: \(productId)")
                    maxFileCount = 0
                    //notifyAlert(self, title: "Yay!", message: "You can no take as many infotos as you want. Go to town!")
                case .Error(_):
                    break
                    ///print("Purchase Failed: \(error)")
                    //notifyAlert(self, title: "Uh Oh", message: "Something went wrong with your purchase. If you have been charged and do not have unlimited infotos please contact support.")
            }
        }
    }
    
    func restorePurcase(){
        SwiftyStoreKit.restorePurchases() { results in
            if results.restoreFailedProducts.count > 0 {
                print("Did not connect")
            }else if results.restoredProductIds.count > 0 {
                maxFileCount = 0
                notifyAlert(self, title: "Yay", message: "Your in-app purchase of unlimited storage has been restored!")
                print("Restore Success: \(results.restoredProductIds)")
            }else {
                notifyAlert(self, title: "", message: "We cannot find your previous in-app purchase. If you believe you have made this purchase please contact support.")
                print("Nothing to Restore")
            }
        }
    }
    
    func segueFile2newFile(action: UIAlertAction!){
        self.performSegueWithIdentifier("file2newFile", sender: action)
    }
    
    func segueFolder2newFile(action: UIAlertAction!){
        self.performSegueWithIdentifier("folder2newFile", sender: action)
    }
    
    func presentNewFileOptions(senderName:String) {
        if (maxFileCount > 0 && getFileCount() >= maxFileCount) {
//            notifyAlert(self, title: "Upgrade to Unlimited", message: "The free version only allows \(maxFileCount) files. Go to menu to upgrade to unlimited files for only $\(PREMIUM_COST).")
//            return
            let title   = "Uprade to Unlimited"
            let message = "The free version only lets you store \(maxFileCount) infotos. Upgrade to unlimited infotos for only $\(PREMIUM_COST)."
            let actionSheetController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Not Now", style: .Default) { action -> Void in
            }
            let okAction: UIAlertAction = UIAlertAction(title: "Upgrade", style: .Default) { action -> Void in
                //// Go to in app purchase
                self.purchaseProduct()
            }
            actionSheetController.addAction(cancelAction)
            actionSheetController.addAction(okAction)
            self.presentViewController(actionSheetController, animated: true, completion: nil)
            return
        }
        
        let ac = UIAlertController(title: "New Infoto", message: nil, preferredStyle: .ActionSheet)
        
        for alertOption in ["Take Photo","Take Video","Choose Photo","Choose Video"] {
            if senderName == "folder"{
                ac.addAction(UIAlertAction(title: alertOption, style: .Default, handler: self.segueFolder2newFile))
            } else {
                ac.addAction(UIAlertAction(title: alertOption, style: .Default, handler: self.segueFile2newFile))
            }
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func showPopupMessage(message:String, seconds:NSTimeInterval = 2.5, widthMult:CGFloat = 0.9, heightMult:CGFloat = 1.0, remove:Bool = true){
        if let superview = self.view.superview {
            while let view = superview.viewWithTag(101) {
                view.removeFromSuperview()
            }
        }else{
            snp()
            return
        }
        
        let heightSize  = CGFloat((Double(message.characters.count) / 50.0) * 30.0) * heightMult
        let mainView    = self.view.superview!
        let labelWidth  = mainView.bounds.width * widthMult
        let label = UILabel(frame: CGRect(x: (mainView.bounds.width - labelWidth)/2, y: (mainView.bounds.height - heightSize)/4, width: labelWidth, height: 60 + heightSize))
        label.text               = message
        label.tag                = 101
        label.textColor          = UIColor.whiteColor()
        label.backgroundColor    = PU_BG_COLOR
        label.textAlignment      = .Center
        label.lineBreakMode      = .ByWordWrapping
        label.numberOfLines      = 20
        label.minimumScaleFactor = 0.5
        label.font               = UIFont(name: "Futura-Medium", size: 17)
        label.adjustsFontSizeToFitWidth = true
        
        let padding = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        let wrapperView:UIView = label.withPadding(padding)
        wrapperView.frame = label.frame
        wrapperView.tag                = 101
        wrapperView.backgroundColor    = PU_BG_COLOR
        wrapperView.layer.cornerRadius = 20.0
        wrapperView.clipsToBounds      = true
        mainView.addSubview(wrapperView)
        
        label.userInteractionEnabled = true
        let gest = UITapGestureRecognizer(target: self, action: #selector(BaseTVC.removePopup))
        gest.numberOfTapsRequired = 1
        label.addGestureRecognizer(gest)
        
        if remove {
            _ = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: #selector(BaseTVC.removePopup), userInfo: nil, repeats: false)
        }
    }
    
    func removePopup(){
        if let superview = self.view.superview {
            UIView.animateWithDuration(0.6, animations: {superview.viewWithTag(101)?.alpha = 0.0},
            completion: {(value: Bool) in
                while let view = superview.viewWithTag(101) {
                    ///let label = view as! UILabel
                    ///print (label.text)
                    view.removeFromSuperview()
                }
            })
        }
    }
    
    //// Delete File
    func deleteFile(file:Files){
        
        if let fn = file.fileName {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(getFilePath(fn))
            } catch {
                snp("Tried to delete file \(file.fileName) but couldn't \(error)")
            }
        }
        
        self.moc.deleteObject(file)
        self.saveContext()
    }
    
    func deleteTempFiles(){
        
        let fetchRequest = NSFetchRequest(entityName: "Files")
        fetchRequest.predicate = NSPredicate(format: "deleteDayNum > 0")
        do {
            let files = try self.moc.executeFetchRequest(fetchRequest) as! [Files]
            for file in files{
                //print("\(file.deleteDayNum) \(file.title!)")
                let seconds = Int(NSDate.timeIntervalSinceReferenceDate() - file.edit_date)
                if seconds > 86400 * Int(file.deleteDayNum){
                    deleteFile(file)
                }
            }
        } catch {
            snp()
            //fatalError("Failed fetch request: \(error)")
        }
    }
    
    //// Creates folder item in core data
    func createFolder(name:String, isLocked:Bool, orderPosition:Int = 0){
        
        let fetchRequest = NSFetchRequest(entityName: "Folders")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        do {
            let fetchResults = try self.moc.executeFetchRequest(fetchRequest)
            if fetchResults.count > 0 {
                //print("\(name) exists!")
                return
            }
        } catch {
            snp()
            //fatalError("Failed fetch request: \(error)")
        }
        
        let newFolder = NSEntityDescription.insertNewObjectForEntityForName("Folders", inManagedObjectContext: self.moc)
        newFolder.setValue(name, forKey: "name")
        newFolder.setValue(isLocked, forKey: "isLocked")
        newFolder.setValue(orderPosition, forKey: "orderPosition")
        saveContext()
        //print("Created Folder: \(name)")
    }

    func saveContext(){
        do {
            try self.moc.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
}

extension UIView{
    func withPadding(padding: UIEdgeInsets) -> UIView{
        let container = UIView()
        self.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        
        container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "|-(\(padding.left))-[view]-(\(padding.right))-|"
        , options: [], metrics: nil, views: ["view": self]))
        container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "V:|-(\(padding.top))-[view]-(\(padding.bottom))-|",
        options: [], metrics: nil, views: ["view": self]))
        
        return container
    }
}

//class PaddingLabel: UILabel {
//    
//    let padding = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
//    
//    override func drawTextInRect(rect: CGRect) {
//        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, padding))
//    }
//    
//    // Override -intrinsicContentSize: for Auto layout code
//    override func intrinsicContentSize() -> CGSize {
//        let superContentSize = super.intrinsicContentSize()
//        let width = superContentSize.width + padding.left + padding.right
//        let heigth = superContentSize.height + padding.top + padding.bottom
//        return CGSize(width: width, height: heigth)
//    }
//    
//    // Override -sizeThatFits: for Springs & Struts code
//    override func sizeThatFits(size: CGSize) -> CGSize {
//        let superSizeThatFits = super.sizeThatFits(size)
//        let width = superSizeThatFits.width + padding.left + padding.right
//        let heigth = superSizeThatFits.height + padding.top + padding.bottom
//        return CGSize(width: width, height: heigth)
//    }
//    
//}