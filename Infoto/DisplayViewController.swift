//
//  DisplayViewController.swift
//  Infoto
//
//  Created by Scott Bridgman on 1/9/16.
//  Copyright © 2016 Tohism. All rights reserved.
//
//  Important TAGS:
//  101: PopUp Message

import UIKit
import MessageUI
import AVKit
import AVFoundation

class DisplayViewController: BaseVC, UITabBarDelegate, UIScrollViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var dataScrollView: UIScrollView!
    var dataImageView = UIImageView()
    var titleLabel   : UILabel!
    var descTextView : UITextView!
    var file         : Files!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //// DESIGN
        self.view.backgroundColor = VC_BG_COLOR
        
        tabBar.delegate         = self
        dataScrollView.delegate = self
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DisplayViewController.scrollViewDoubleTapped(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 1
        dataScrollView.addGestureRecognizer(doubleTapRecognizer)
        
        if file.fileType == "Photo" {
            
            if let image = UIImage(contentsOfFile: getFilePath(file.fileName!)){
            
                dataImageView = UIImageView(image: image)
                dataImageView.contentMode  = UIViewContentMode.Center
                dataImageView.frame        = CGRect(origin: CGPoint(x: 0, y: 0), size:image.size)
                dataScrollView.contentSize = image.size
                
                let scaleWidth  = self.view.bounds.width / dataScrollView.contentSize.width
                let scaleHeight = self.view.bounds.height / dataScrollView.contentSize.height
                let minScale    = min(scaleWidth, scaleHeight)
                
                dataScrollView.minimumZoomScale = minScale
                dataScrollView.maximumZoomScale = 1.0
                dataScrollView.zoomScale        = minScale
                dataScrollView.addSubview(dataImageView)
            }
            
        } else if file.fileType == "Video" {
            
            dataScrollView.userInteractionEnabled = true
            dataImageView.hidden                  = true
            let url           = NSURL(fileURLWithPath: getFilePath(file.fileName!))
            let avPlayerVC    = AVPlayerViewController()
            let player        = AVPlayer(URL: url)
            avPlayerVC.player = player
            self.addChildViewController(avPlayerVC)
            avPlayerVC.view.frame = CGRectMake(0,0,dataScrollView.bounds.width, dataScrollView.bounds.height)
            avPlayerVC.view.tag   = 20
            dataScrollView.addSubview(avPlayerVC.view)
        }
        
        //// CREATE LABELS FOR TITLE AND DESC
        let width       = self.view.bounds.width * 0.9
        titleLabel      = UILabel(frame: CGRect(x: (view.bounds.width - width)/2, y: self.view.bounds.height * 0.4, width: width, height: 30))
        titleLabel.text = (file.title == "") ? "No Title" : file.title
        titleLabel.backgroundColor    = VC_FG_COLOR
        titleLabel.layer.cornerRadius = 14.0
        titleLabel.clipsToBounds      = true
        titleLabel.textAlignment      = .Center
        titleLabel.font             = UIFont(name: "Futura-Medium", size: 20)
        titleLabel.hidden             = true
        
        view.addSubview(titleLabel)
        
        
        descTextView      = UITextView(frame: CGRect(x: (view.bounds.width - width)/2, y: self.view.bounds.height * 0.4 + 40, width: width, height: self.view.bounds.height * 0.4))
        descTextView.text = (file.desc == "") ? "No description" : file.desc
        descTextView.backgroundColor    = VC_FG_COLOR
        descTextView.layer.cornerRadius = 14.0
        descTextView.clipsToBounds      = true
        descTextView.font               = UIFont(name: "Futura-Medium", size: 20)
        descTextView.hidden             = true
        descTextView.selectable         = true
        descTextView.editable           = false
        
        let singleTapGest2 = UITapGestureRecognizer(target: self, action: #selector(DisplayViewController.toggleDetails))
        singleTapGest2.numberOfTapsRequired = 1
        descTextView.addGestureRecognizer(singleTapGest2)
        
        view.addSubview(descTextView)
        
        tabBar.tintColor = UIColor.lightGrayColor()
    }
    
    func scrollViewDoubleTapped(recognizer: UITapGestureRecognizer) {
        
        let pointInView = recognizer.locationInView(dataImageView)
        var newZoomScale = dataScrollView.zoomScale * 1.5
        newZoomScale = min(newZoomScale, dataScrollView.maximumZoomScale)
        let scrollViewSize = dataScrollView.bounds.size
        
        var x,y,w,h:CGFloat
        if (newZoomScale < min(dataScrollView.maximumZoomScale,dataScrollView.minimumZoomScale * 4)) {
            w = scrollViewSize.width / newZoomScale
            h = scrollViewSize.height / newZoomScale
            x = pointInView.x - (w / 2.0)
            y = pointInView.y - (h / 2.0)
        }else{
            w = scrollViewSize.width / dataScrollView.minimumZoomScale
            h = scrollViewSize.height / dataScrollView.minimumZoomScale
            x = pointInView.x - (w / 2.0)
            y = pointInView.y - (h / 2.0)
        }
        
        let rectToZoomTo = CGRectMake(x, y, w, h);
        dataScrollView.zoomToRect(rectToZoomTo, animated: true)
    }
    
    func centerScrollViewContents() {
        dataImageView.frame = dataImageView.frame
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return dataImageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
        switch(item.tag){
            
        case 0:
            //// Pop this view controller and got back to files
            self.dismissViewControllerAnimated(true, completion: nil)
        case 1:
            //// Send Text
            let messageVC = MFMessageComposeViewController()
            messageVC.messageComposeDelegate = self
            //messageVC.recipients = ["1-312-607-6986"]
            let title = (file.title! == "No Title") ? "" : "\(file.title!)"
            let desc  = (file.desc! == "") ? "" : "\n\(file.desc!)"
            messageVC.body = "\(title)\(desc)"
            
            if file.fileType == "Photo" {
                
                if let image = UIImage(contentsOfFile: getFilePath(file.fileName!)){
                    messageVC.addAttachmentData(UIImageJPEGRepresentation(image, 1)!, typeIdentifier: "image/jpg", filename: "\(APP_NAME)_\(file.fileName!).jpg")
                }
                
            } else if file.fileType == "Video" {
                
                if let videoData = NSData(contentsOfURL: NSURL(fileURLWithPath: getFilePath(file.fileName!))) {
                    messageVC.addAttachmentData(videoData, typeIdentifier: "public.data", filename: "\(APP_NAME)_\(file.fileName!).mov")
                }
            }
            
            if MFMessageComposeViewController.canSendText() &&  MFMessageComposeViewController.canSendAttachments(){
                self.presentViewController(messageVC, animated: false, completion: nil)
            }
            
        case 2:
            //// Send Email
            let title = (file.title! == "No Title") ? "" : "\n\(file.title!)"
            let desc  = (file.desc! == "") ? "" : "\n\(file.desc!)"
            let body = "\(title)\(desc)"
            let emailVC = MFMailComposeViewController()
            emailVC.mailComposeDelegate = self
            
            
            if file.fileType == "Photo" {
                
                if let image = UIImage(contentsOfFile: getFilePath(file.fileName!)){
                    emailVC.addAttachmentData(UIImageJPEGRepresentation(image, 1)!, mimeType: "image/jpg", fileName: "\(APP_NAME)_\(file.fileName!)")
                }
                
            } else if file.fileType == "Video" {
                
                if let videoData = NSData(contentsOfURL: NSURL(fileURLWithPath: getFilePath(file.fileName!))) {
                    emailVC.addAttachmentData(videoData, mimeType: "public.data", fileName: "\(APP_NAME)_\(file.fileName!)")
                }
            }
            
            let subjectLine = (file.title! == "No Title") ? "\(APP_NAME)!" : "\(APP_NAME): \(file.title!)"
            
            emailVC.setSubject(subjectLine)
            emailVC.setMessageBody(body, isHTML: false)
            presentViewController(emailVC, animated: true, completion: nil)
            
        case 3:
            //// Save content to camera roll
            if file.fileType == "Photo" {
                
                if let image = UIImage(contentsOfFile: getFilePath(file.fileName!)){
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    showPopupMessage("Photo saved to camera roll")
                }
                
            } else if file.fileType == "Video" {
                
                if let _ = NSData(contentsOfURL: NSURL(fileURLWithPath: getFilePath(file.fileName!))) {
                    UISaveVideoAtPathToSavedPhotosAlbum(getFilePath(file.fileName!),nil,nil,nil)
                    showPopupMessage("Video saved to camera roll")
                }
            }
        case 4:
            //// Show Title and Description
            toggleDetails()
        default:
            break
        }
    }
    
    func toggleDetails(){
        let alphaVal:CGFloat = (self.titleLabel.hidden) ? 1.0 : 0.0
        let animateOpt       = (self.titleLabel.hidden) ? UIViewAnimationOptions.CurveEaseIn : UIViewAnimationOptions.CurveEaseOut
        
        if self.titleLabel.hidden {
            self.titleLabel.alpha  = 0.0
            self.titleLabel.hidden = false
        }
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: animateOpt, animations: {self.titleLabel.alpha = alphaVal},
            completion: {(value: Bool) in
                if alphaVal == 0.0 {
                    self.titleLabel.hidden = !self.titleLabel.hidden
                }
        })
        
        if self.descTextView.hidden {
            self.descTextView.alpha  = 0.0
            self.descTextView.hidden = false
        }
        
        UIView.animateWithDuration(0.4, delay: 0.0, options: animateOpt, animations: {self.descTextView.alpha = alphaVal},
            completion: {(value: Bool) in
                if alphaVal == 0.0 {
                    self.descTextView.hidden = !self.descTextView.hidden
                }
        })
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        
        switch (result) {
            
            case MessageComposeResultCancelled:
                self.dismissViewControllerAnimated(true, completion: nil)
                
            case MessageComposeResultFailed:
                self.dismissViewControllerAnimated(true, completion: { action -> Void in
                    notifyAlert(self, title: "Uh Oh", message: "Message failed to send.")
                })
            
            case MessageComposeResultSent:
                self.dismissViewControllerAnimated(true, completion: { action -> Void in
                    self.showPopupMessage("Text Sent!", seconds: 1.5)
                })
                
            default:
                snp()
                self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch (result){
            case MFMailComposeResultCancelled:
                self.dismissViewControllerAnimated(true, completion: nil)
            case MFMailComposeResultFailed:
                self.dismissViewControllerAnimated(true, completion: { action -> Void in
                    notifyAlert(self, title: "Uh Oh", message: "Something went wrong and email did not send")
                })
            case MFMailComposeResultSent:
                self.dismissViewControllerAnimated(true, completion: { action -> Void in
                    self.showPopupMessage("Email Sent!", seconds: 1.5)
                })
            default:
                self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
