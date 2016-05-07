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
    
    let menuItems = ["What's an infoto?",
                     "Reset tips",
                     "Suggestions",
                     "Important Note!",
                     "Rate Us",
                     "Support & Feedback",
                     "Upgrade: Unlimited infotos for $\(PREMIUM_COST)"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        return cell
    }
    
    func easyTipViewDidDismiss(tipView : EasyTipView){
        tipIsOpen = false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.row){
        case 0:
            let msgStr = "Infotos are photos and videos used for storing information. Infotos are awesome but people hesitate to take them. After all who wants to litter their camera roll with tons of infotos just to spend time digging for them when they're needed? This app solves both those problems by housing all of your infotos for you!"
            showPopupMessage(msgStr, widthMult:0.9, heightMult:0.4, remove:false)
        case 1:
            self.removePopup()
            
            activeTips = fullTipList
            
            if !tipIsOpen {
                tipIsOpen = true
            
                guard let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as? MenuCell else {
                    break
                }
                let prefs = getTipPreferences()
                EasyTipView.show(forView: cell,
                         withinSuperview: self.tableView,
                         text: "Popup tips will guide you through the app. Tap them to dismiss.",
                         preferences: prefs,
                         delegate: self)
            }
            
        case 2:
            performSegueWithIdentifier("menu2suggest", sender: indexPath)
        case 3:
            showPopupMessage("Every day is a cloudless day here. All infotos are only stored on the phone and not synced to any clouds.", widthMult:0.9, heightMult:0.4, remove:false)
            break
        case 4:
            break
        case 5:
            //UIApplication.sharedApplication().openURL(NSURL(string : "LINK_GOES_HERE")!)
            break
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
