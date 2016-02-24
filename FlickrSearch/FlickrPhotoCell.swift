//
//  FlickrPhotoCell.swift
//  FlickrSearch
//
//  Created by Matthew Linaberry on 2/24/16.
//  Copyright © 2016 MRS Electronic, Inc. All rights reserved.
//

import UIKit

class FlickrPhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selected = false
    }
    
    override var selected : Bool {
        didSet {
            self.backgroundColor = selected ? themeColor : UIColor.blackColor()
        }
    }
    
}
