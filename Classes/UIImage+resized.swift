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
            
            if size.width == size.height, size.width <= 2000{
                for x in [2000, 1800, 1600, 1400, 1200, 1000, 800, 600, 500, 400, 300, 240, 220, 200, 180, 160, 150, 140, 120, 110, 100, 80, 70, 60]{
                    if size.width < CGFloat(x){
                        let allReadyResizedVersionPath = path.appending("_").appendingFormat("%d", x).appending("-").appendingFormat("%d", x).appending(".").appending(fileExtension)
                        
                        if FileManager.default.fileExists(atPath: allReadyResizedVersionPath) {
                            originalImagePath = allReadyResizedVersionPath
                            break
                        }
                    }
                }
            }
            
            if let originalData = try? Data(contentsOf: URL(filePath: originalImagePath)),
               var saveImage = UIImage.downsample(data: originalData,
                                                  maxPixelSize: max(size.width*UIScreen.main.scale, size.height*UIScreen.main.scale)) {
                
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
        return nil
    }
    
    class func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false  // Kein Caching des vollen Bildes
        ]
        
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return nil
        }
        
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,  // Sofort dekodieren
            kCGImageSourceCreateThumbnailWithTransform: true,  // EXIF-Rotation
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }

    func resizeImage(_ size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
