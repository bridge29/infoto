//
//  SuggestTVController.swift
//  Infoto
//
//  Created by Scott Bridgman on 4/28/16.
//  Copyright © 2016 Tohism. All rights reserved.
//

import UIKit

class SuggestTVController: UITableViewController {

    let suggestItems = [["Receipts","Make sure your waiter knew that was a 5 and not a 9 on your tip."],
                        ["Ads","In case you decide later to give that crossfit class a try."],
                        ["Shopping","Torn on buying a shirt? Infoto it now and sleep on it (a great remedy for buyer's remorse)."],
                        ["Past Haircuts","Show your barber all of his past work, the good the bad and the ugly."],
                        ["Gym Classes","No more re-googling your gym's class scheudule everyday."],
                        ["Recipes","Take your recipe book with you into the grocery store."],
                        ["Travel Info","Don't rely on an internet connection to pull up your boarding pass."],
                        ["Where you Parked","A quick infoto of Level G-7 will save you that dreadful car search."],
                        ["General Info","Have your drivers license or passport info on you at all times."],
                        ["Come up with your own!","Once you start using infotos to capture useful info, you'll discover all kinds of ways to use them."]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Infoto Suggestions"
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SuggestCell", forIndexPath: indexPath)

        // Configure the cell...
        cell.textLabel?.text = suggestItems[indexPath.row][0]
        cell.textLabel?.font = UIFont(name: "Chalkboard SE", size:18)
        cell.detailTextLabel?.lineBreakMode = .ByWordWrapping
        cell.detailTextLabel?.numberOfLines = 3
        cell.detailTextLabel?.text = suggestItems[indexPath.row][1]
        return cell
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
