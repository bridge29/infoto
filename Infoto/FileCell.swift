//
//  FileCell.swift
//  Infoto
//
//  Created by Scott Bridgman on 2/21/16.
//  Copyright © 2016 Tohism. All rights reserved.
//

import UIKit

class FileCell: UITableViewCell, UIScrollViewDelegate {

    @IBOutlet weak var vertStackView: UIStackView!
    @IBOutlet weak var titleDateStackView: UIStackView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dataScrollView: UIScrollView!
    var dataImageView = UIImageView()
    var file: Files!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.backgroundColor = VC_BG_COLOR
        dataScrollView.delegate = self
        
        let singleTapGest = UITapGestureRecognizer(target: self, action: #selector(FileCell.scrollViewDoubleTapped(_:)))
        singleTapGest.numberOfTapsRequired = 1
        dataScrollView.addGestureRecognizer(singleTapGest)
        
        descTextView.scrollEnabled = false
        descTextView.layer.cornerRadius = 10
    }
    
    func configureImageView(image:UIImage, currView:FilesView){
        dataImageView.removeFromSuperview()
        dataImageView              = UIImageView(image: image)
        dataImageView.contentMode  = UIViewContentMode.Center
        dataImageView.frame        = CGRect(origin: CGPoint(x: 0, y: 0), size:image.size)
        dataScrollView.contentSize = image.size
        dataImageView.hidden       = false
        
        let scrollViewFrame = dataScrollView.frame
        let scaleWidth      = scrollViewFrame.size.width / dataScrollView.contentSize.width
        let scaleHeight     = scrollViewFrame.size.height / dataScrollView.contentSize.height
        let minScale        = min(scaleWidth, scaleHeight)
        let maxScale        = max(scaleWidth, scaleHeight)
        dataScrollView.minimumZoomScale = minScale
        dataScrollView.maximumZoomScale = 1.0
        dataScrollView.zoomScale        = (currView == .Small) ? maxScale : minScale
        dataScrollView.addSubview(dataImageView)
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
        let boundsSize = dataScrollView.bounds.size
        var contentsFrame = dataImageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        dataImageView.frame = contentsFrame
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return dataImageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()
    }
}
