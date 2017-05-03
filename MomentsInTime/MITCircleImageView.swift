//
//  MITCircleImageView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/29/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

fileprivate let imageCache = NSCache<NSString, AnyObject>()

class MITCircleImageView: UIImageView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.width * 0.5
    }
    
    //MARK: Public
    
    func loadLocalImage(withUrl urlString: String)
    {
        //check cache for image:
        if let imageFromCache = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = imageFromCache
        }
        else {
            
            //if no image, fetch from disk and cache:
            if let fetchedImage = loadImageFromDisk(withUrlString: urlString) {
                self.image = fetchedImage
                imageCache.setObject(fetchedImage, forKey: urlString as NSString)
            }
        }
    }
    
    //MARK: Private
    
    private func loadImageFromDisk(withUrlString urlString: String) -> UIImage?
    {
        print("\nLoading image from disk\n")
        
        if let imageURL = URL(string: urlString),
            let imageData = try? Data.init(contentsOf: imageURL, options: []) {
            return UIImage(data: imageData)
        }
        
        return nil
    }
    
    private func setup()
    {
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
        self.addBorder()
    }
    
    private func addBorder()
    {
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1.0 / UIScreen.main.scale
        self.layer.cornerRadius = self.frame.size.height * 0.5
        self.layer.masksToBounds = true
    }
}
