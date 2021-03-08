//
//  UIImageView+LoadImage.swift
//  JxContentTable
//
//  Created by Jeanette Müller on 09.11.20.
//

import UIKit
import JxSwiftHelper

public extension UIImageView {
    
    func loadImageFromHttpPath(path: String, fallbackImage: UIImage, contentMode: UIView.ContentMode, withCustomSize customSize: CGSize? = nil) {
        
        var size = self.frame.size
        
        if let c = customSize {
            size = c
        }
        
        let quadratSize = CGSize(width: max(size.width, size.height), height: max(size.width, size.height))
        
        if let localImage = UIImage(named: path) {
            self.image = localImage
        } else if let imageFromFile = UIImage.getImage(withImageString: path, andSize: quadratSize, withMode: contentMode) {
            self.image = imageFromFile
        } else if let photoDetails = PhotoRecord(string: path) {
            photoDetails.image = fallbackImage
            photoDetails.contentMode = contentMode
            startDownloadForRecord(photoDetails: photoDetails)
        } else {
            self.image = fallbackImage
        }
    }
    
    func startDownloadForRecord(photoDetails: PhotoRecord) {
        
        self.image = photoDetails.image
        
        let imageLoader = ImageDownloader(photoRecord: photoDetails)
        
        imageLoader.completionBlock = {
            DispatchQueue.main.async {
                
                let size = self.frame.size
                let quadratSize = CGSize(width: max(size.width, size.height), height: max(size.width, size.height))

                if let imageFromFile = UIImage.getImage(withImageString: photoDetails.path,
                                                        andSize: quadratSize,
                                                        withMode: photoDetails.contentMode) {
                    self.image = imageFromFile
                }
            }
        }
        
        PendingImageOperations.shared.downloadQueue.addOperation(imageLoader)
    }
}
