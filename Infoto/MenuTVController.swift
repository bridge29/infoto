//
//  MenuTVController.swift
//  Infoto
//
//  Created by Scott Bridgman on 3/10/16.
//  Copyright © 2016 Tohism. All rights reserved.
//

import UIKit
import EasyTipView

class MenuTVController: BaseTVC, EasyTipViewDelegate {
    
    var menuItems = ["What's an infoto?",
                     "Sort Folders",
                     "Suggestions",
                     "Reset tips",
                     "Support & Feedback",
                     "Rate Us"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if maxFileCount > 0 {
            menuItems.append("Upgrade to Unlimited infotos")
            menuItems.append("Restore your in-app purchase")
        }
        
        //self.view.backgroundColor = VC_BG_COLOR
        navigationItem.title = "Menu"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return menuItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MenuCell", forIndexPath: indexPath)

        // Configure the cell...
        cell.textLabel?.text = menuItems[indexPath.row]
        cell.textLabel?.font = UIFont(name: "Chalkboard SE", size:20)
        return cell
    }
    
    func easyTipViewDidDismiss(tipView : EasyTipView){
        tipIsOpen = false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.row){
        case 0:
            let msgStr = "Infotos are photos and videos\nused for storing information.\nINFO + PHOTO = INFOTO\nThis app lets you easily take, store, and organize all the infotos you can think of without littering your camera roll."
            showPopupMessage(msgStr, widthMult:0.9, heightMult:0.4, remove:false)
        case 1:
            sortFolderMode = true
            self.navigationController?.popViewControllerAnimated(true)
        case 2:
            performSegueWithIdentifier("menu2suggest", sender: indexPath)
//        case 3:
//            showPopupMessage("All infotos are only stored on the phone (it is not synced anywhere else). The reason is you'll find most content will only be needed in the near future and we do not want to litter your icloud with them.", widthMult:0.9, heightMult:0.4, remove:false)
        case 3:
            self.removePopup()
            
            activeTips = fullTipList
            
            if !tipIsOpen {
                tipIsOpen = true
                
                guard let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as? MenuCell else {
                    break
                }
                let prefs = getTipPreferences()
                EasyTipView.show(forView: cell,
                                 withinSuperview: self.tableView,
                                 text: "Popup tips will guide you through the app. Tap them to dismiss.",
                                 preferences: prefs,
                                 delegate: self)
            }
        case 4:
            UIApplication.sharedApplication().openURL(NSURL(string:"http://tohism.com/infotos-app")!)
            break
        case 5:
            rateNumber = 0
            UIApplication.sharedApplication().openURL(NSURL(string:"http://appsto.re/us/JZfpcb.i")!)
            break
        case 6:
            self.purchaseProduct()
        case 7:
            self.restorePurcase()
        default:
            snp()
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
