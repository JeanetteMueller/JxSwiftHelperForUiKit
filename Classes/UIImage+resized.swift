//
//  UIImage+resized.swift
//  ProjectPhoenix
//
//  Created by Jeanette Müller on 03.11.16.
//  Copyright © 2016 Jeanette Müller. All rights reserved.
//

import UIKit
import JxSwiftHelper

open class UIImageCache:NSCache<NSString, UIImage> {
    static let shared: UIImageCache = {
        
        let instance = UIImageCache()
        
        // setup code
        
        return instance
    }()
}
public extension UIViewController {
    func cleanCaches() {
        
        UIImageCache.shared.removeAllObjects()
        
        //        DataStore.shared.episodesCache.removeAllObjects()
    }
}
public extension UIImage {

    class func getFilePath(withUrl url:URL) -> String {
        
        let imageDir = FileHelper.shared.getImagesFolderPath()
        
        return imageDir.appending("/").appending(url.md5())
    }
    class func getFilePath(urlString:String) -> String {
        
        let imageDir = FileHelper.shared.getImagesFolderPath()
        
        return imageDir.appending("/").appending(urlString.md5())
    }
    class func getImage(imageString:String, size:CGSize?, mode:UIView.ContentMode, useCache:Bool = true) -> UIImage?{
        
        if let i = UIImage(named: imageString){
            return i
        }
        
        let imagePath = UIImage.getFilePath(urlString: imageString)
        if !FileManager.default.fileExists(atPath: imagePath){
            return nil
        }
        return UIImage.getImage(path: imagePath, size: size, mode: mode, useCache: useCache)

    }
    class func getImage(path:String, size:CGSize?, mode:UIView.ContentMode, useCache:Bool = true) -> UIImage?{
        var useSize:CGSize
        
        if var mySize = size {

            if mySize.width < 50 || mySize.height < 50 {
                
                mySize = CGSize(width: 50, height: 50)
            }
            
            let factor = mySize.width / mySize.height
            
            let newHeight = CGFloat(10 * Int(ceil(mySize.height / 10.0)))
            
            useSize = CGSize(width: newHeight * factor, height: newHeight)
            
        }else{
            useSize = CGSize(width: 1000, height: 1000)
        }
        
        var image:UIImage? = nil
        if let imagePathWithSize = UIImage.pathToResizedImage(path: path, size: useSize, mode: mode, useCache: useCache){
            
            if let storedImage = UIImageCache.shared.object(forKey: imagePathWithSize as NSString){
                return storedImage
            }else{
                image = UIImage(contentsOfFile: imagePathWithSize)
                if let storeImage = image{
                    if useCache{
                        UIImageCache.shared.setObject(storeImage, forKey: imagePathWithSize as NSString)
                    }
                    return storeImage
                }
            }
        }
        return nil
    }
    class func pathToResizedImage(urlString:String, size:CGSize, mode:UIView.ContentMode) -> String? {
        let sourcePath = UIImage.getFilePath(urlString: urlString)
        
        return UIImage.pathToResizedImage(path: sourcePath, size: size, mode: mode)
    }
    class func pathToResizedImage(path:String, size:CGSize, mode:UIView.ContentMode, fileExtension:String = "png", asGrayscale: Bool = false, useCache:Bool = true) -> String? {
        if FileManager.default.fileExists(atPath: path) {

            let modeString = String(format: "mode_%d", mode.rawValue)
            
            let grayString = asGrayscale ? "bw-": ""
            
            let newFilename = path
                .appending("_")
                .appendingFormat("%d", Int(size.width))
                .appending("-")
                .appendingFormat("%d", Int(size.height))
                .appending("-")
                .appending(grayString)
                .appending(modeString)
                .appending(".")
                .appending(fileExtension)
            
            if FileManager.default.fileExists(atPath: newFilename) {
                //log("resized file exitiert schon", newFilename)
                return newFilename
            }
            
            var originalImagePath = path
            
            if size.width == size.height{
                //quadrat
                if size.width < 1000{
                    
                    for x in [1000, 800, 600, 500, 400, 300, 240, 220, 200, 180, 160, 150, 140, 120, 110, 100, 80, 70, 60]{
                        
//                        log("imagesize with width", x)
                        if size.width < CGFloat(x){
                            let allReadyResizedVersionPath = path.appending("_").appendingFormat("%d", x).appending("-").appendingFormat("%d", x).appending(".").appending(fileExtension)
                            
                            if FileManager.default.fileExists(atPath: allReadyResizedVersionPath) {
                                originalImagePath = allReadyResizedVersionPath
                                break
                            }
                        }
                    }
                }
            }
            
            if let original = UIImage(contentsOfFile: originalImagePath){
                
                if var saveImage = UIImage.createImage(original: original, size: size, mode: mode) {
                    if asGrayscale {
                        saveImage = saveImage.grayScaleImage()
                    }
                    if let imageData = saveImage.pngData() as NSData?{
                    
                        if FileManager.default.fileExists(atPath: newFilename) {
                            //log("resized file exitiert schon", newFilename)
                            try? FileManager.default.removeItem(atPath: newFilename)
                        }
                        imageData.write(toFile: newFilename as String, atomically: true)
                    
                    }
                    if useCache {
                        UIImageCache.shared.setObject(saveImage, forKey: newFilename as NSString)
                    }
                    let url = URL(fileURLWithPath: newFilename)
                    
                    if url.skipBackupAttributeToItemAtURL(true){
                        //log("downloaded file is excluded from backup")
                    }else{
                        log("UIImage: pathToResizedImage - exclude from backup failed:", url)
                    }
                    
                    return newFilename;
                }
            }
        }
        return nil
    }
    
    class func createImage(original: UIImage, size:CGSize, mode:UIView.ContentMode) -> UIImage?{
//        log("create resized image")
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        UIRectFill(CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        
        let ratioX = original.size.width / size.width
        let ratioY = original.size.height / size.height
        
        //max zeigt ganzes bild mit schwarzen balken
        //min vergrößert das bild und schneidet den rest ab
        
        var ratio:CGFloat = 0
        
        switch mode {
        case .scaleAspectFill, .scaleToFill:
            ratio = min(ratioX, ratioY)
            
            let newWidth = original.size.width/ratio
            let newHeight = original.size.height/ratio
            
            original.draw(in: CGRect(x: (size.width - newWidth) / 2,
                                     y: (size.height - newHeight) / 2,
                                     width: newWidth,
                                     height: newHeight))
            
        default:
            ratio = max(ratioX, ratioY)
            
            var originX: CGFloat = 0
            var originY: CGFloat = 0
            let sizeWidth: CGFloat = original.size.width/ratio
            let sizeHeight: CGFloat = original.size.height/ratio
            
            switch mode {
                
            case .top:
                originX = (size.width - sizeWidth) / 2
                originY = 0
            case .bottom:
                originX = (size.width - sizeWidth) / 2
                originY = size.height - sizeHeight
            case .topLeft:
                originX = 0
                originY = 0
            default:
                originX = (size.width - sizeWidth) / 2
                originY = (size.height - sizeHeight) / 2
            }
            
            original.draw(in: CGRect(x: originX,
                                     y: originY,
                                     width: sizeWidth,
                                     height: sizeHeight))
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func getQuadratImage(andCropToBounds crop: Bool = true) -> UIImage {
        
        let image = self
        var quadratSize = CGSize(width: 100, height: 100)
        
        if crop {
            quadratSize = CGSize(width: min(image.size.width, image.size.height), height: min(image.size.width, image.size.height))
        } else {
            quadratSize = CGSize(width: max(image.size.width, image.size.height), height: max(image.size.width, image.size.height))
        }
        
        UIGraphicsBeginImageContextWithOptions(quadratSize, false, 0.0)
        
        image.draw(in: CGRect(x: (quadratSize.width - image.size.width) / 2,
                              y: (quadratSize.height - image.size.height) / 2,
                              width: image.size.width,
                              height: image.size.height))
        
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return newImage
        } else {
            UIGraphicsEndImageContext()
            return image
        }
    }
}
