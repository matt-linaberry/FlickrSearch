//
//  FlickrPhotosViewController.swift
//  FlickrSearch
//
//  Created by Matthew Linaberry on 2/23/16.
//  Copyright © 2016 MRS Electronic, Inc. All rights reserved.
//

import UIKit


class FlickrPhotosViewController: UICollectionViewController {
    private let reuseIdentifier = "flickrCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    private var searches = [FlickrSearchResults]()
    private let flickr = Flickr()
    
    private var selectedPhotos = [FlickrPhoto]()
    private let shareTextLabel = UILabel()
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    func updateSharedPhotoCount() {
        shareTextLabel.textColor = themeColor
        shareTextLabel.text = "\(selectedPhotos.count) photos selected."
        shareTextLabel.sizeToFit()
    }
    
    @IBAction func share(sender: AnyObject) {
        print("yeah you pressed the share buton")
        if searches.isEmpty {
            return
        }
        if !selectedPhotos.isEmpty {
            var imageArray = [UIImage]()
            for photo in self.selectedPhotos {
                imageArray.append(photo.thumbnail!)
            }
            let shareScreen = UIActivityViewController(activityItems: imageArray, applicationActivities: nil)
            
            shareScreen.modalPresentationStyle = UIModalPresentationStyle.Popover
            self.presentViewController(shareScreen, animated: true, completion: nil)
            
            var popover = shareScreen.popoverPresentationController!
            popover.permittedArrowDirections = UIPopoverArrowDirection.Any
            popover.barButtonItem = sender as? UIBarButtonItem
        }
        sharing = !sharing
    }
    var sharing : Bool = false {
        didSet {
            collectionView?.allowsMultipleSelection = sharing
            collectionView?.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None)
            selectedPhotos.removeAll(keepCapacity: false)
            if sharing && largePhotoIndexPath != nil {
                largePhotoIndexPath = nil
            }
            
            let shareButton = self.navigationItem.rightBarButtonItems!.first! as UIBarButtonItem
            if sharing {
                updateSharedPhotoCount()
                let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
                navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
            }
            else {
                navigationItem.setRightBarButtonItems([shareButton], animated: true)
            }
        }
    }
    
    var largePhotoIndexPath: NSIndexPath? {
        didSet {
            var indexPaths = [NSIndexPath]()
            if largePhotoIndexPath != nil {
                indexPaths.append(largePhotoIndexPath!)
            }
            if oldValue != nil {
                indexPaths.append(oldValue!)
            }
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
                return
                }){
                    completed in
                    if self.largePhotoIndexPath != nil {
                        self.collectionView?.scrollToItemAtIndexPath(self.largePhotoIndexPath!, atScrollPosition: .CenteredVertically, animated: true)
                    }
            }
        }
    }
    
    func photoForIndexPath(indexPath: NSIndexPath) -> FlickrPhoto {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FlickrPhotoCell
        let flickrPhoto = photoForIndexPath(indexPath)
        
        cell.activityIndicator.stopAnimating()
        
        if indexPath != largePhotoIndexPath {
            cell.imageView.image = flickrPhoto.thumbnail
            return cell
        }
        
        if flickrPhoto.largeImage != nil {
            cell.imageView.image = flickrPhoto.largeImage
            return cell
        }
        cell.imageView.image = flickrPhoto.thumbnail
        
        cell.activityIndicator.startAnimating()
        
        flickrPhoto.loadLargeImage{
            loadedFlickrPhoto, error in
            
            cell.activityIndicator.stopAnimating()
            if error != nil {
                return
            }
            
            if loadedFlickrPhoto.largeImage == nil {
                return
            }
            
            if indexPath == self.largePhotoIndexPath {
                if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrPhotoCell {
                    cell.imageView.image = loadedFlickrPhoto.largeImage
                }
            }
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "FlickrPhotoHeaderView", forIndexPath: indexPath) as! FlickrPhotoHeaderView
            headerView.label.text = searches[indexPath.section].searchTerm
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if sharing {
            return true
        }
        if largePhotoIndexPath == indexPath {
            largePhotoIndexPath = nil
        }
        else {
            largePhotoIndexPath = indexPath
        }
        return false
    }
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if sharing {
            let photo = photoForIndexPath(indexPath)
            selectedPhotos.append(photo)
            updateSharedPhotoCount()
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if sharing {
            if let foundIndex = selectedPhotos.indexOf(photoForIndexPath(indexPath)) {
                selectedPhotos.removeAtIndex(foundIndex)
                updateSharedPhotoCount()
            }
        }
    }
}

extension FlickrPhotosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flickrPhoto = photoForIndexPath(indexPath)
        
        if indexPath == largePhotoIndexPath {
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickrPhoto.sizeToFillWidthOfSize(size)
        }
        
        if var size = flickrPhoto.thumbnail?.size {
            size.width += 10
            size.height += 10
            return size
        }
        return CGSize(width: 100,height: 100)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
}

extension FlickrPhotosViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        flickr.searchFlickrForTerm(textField.text!) {
            results, error in
            
            activityIndicator.removeFromSuperview()
            if error != nil {
                print("Error searching : \(error)")
            }
            
            if results != nil {
                print("Found \(results!.searchResults.count) matching \(results!.searchTerm)")
                self.searches.insert(results!, atIndex: 0)
                self.collectionView?.reloadData()
            }
        }
        textField.text = nil
        textField.resignFirstResponder()  // close the keyboard
        return true
    }
}
