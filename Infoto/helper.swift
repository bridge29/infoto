//
//  helper.swift
//  PicPrank
//
//  Created by Scott Bridgman on 7/22/15.
//  Copyright (c) 2015 Tohism. All rights reserved.
//

import UIKit


func printClassName(obj : AnyObject){
    let objectClass : AnyClass! = object_getClass(obj)
    let className = objectClass.description()
    print(className)
}

func pl(msg:String){
    print(msg)
}

func plx(){
    print("xxx")
}

func plt(){
    print(NSDate().timeIntervalSince1970)
}

func snp(msg:String = ""){
    print("SHOULD NOT PRINT " + msg)
}

func notifyAlert(target:UIViewController, title:String, message:String) {
    let actionSheetController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .Default) { action -> Void in
    }
    actionSheetController.addAction(okAction)
    target.presentViewController(actionSheetController, animated: true, completion: nil)
}

///// Infoto Helper

func printFileContents(){
    print("Contents in \(getDocumentPath())")
    do {
        let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(getDocumentPath())
        for content in contents{
            print(content)
        }
    } catch {
        fatalError("Error pulling contents: \(error)")
    }
    
}


