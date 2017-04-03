//
//  CachedImageView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import Alamofire

//global imageCache:
private let imageCache = NSCache<NSString, AnyObject>()

class CachedImageView: UIImageView
{
    var imageURLString: String?
    
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
    
    private func setup()
    {
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
    
    //urlString will be the key for the imageCache
    func loadImageFromCache(withUrlString urlString: String)
    {
        self.imageURLString = urlString
        
        //need to nil out image so that we aren't displaying the wrong image
        //before network request returns, or from a reused cell
        self.image = nil
        
        //first check for cached image:
        if let imageFromCache = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = imageFromCache
            return
        }
        
        //if no previously cached image exists, fetch it and add it to the cache:
        CachedImageView.fetchImage(with: urlString) { (image, error) in
            
            if let imageToCache = image {
                
                DispatchQueue.main.async { [weak self] in
                    
                    /**
                     * since we are reusing cells, when this network request finishes, this UIImage will update its image,
                     * but user may have scrolled so that the cell should be displaying a different image,
                     * so we need to verify that we are still working w/ the same url.
                     */
                    if self?.imageURLString == urlString {
                        self?.image = imageToCache
                    }
                    
                    imageCache.setObject(imageToCache, forKey: urlString as NSString)
                }
            }
        }
    }
    
    class func fetchImage(with urlString: String, completion: @escaping (UIImage?, Error?) -> Void)
    {
        if let url = URL(string: urlString) {
            
            Alamofire.request(url).responseData { response in
                
                switch response.result {
                case .success:
                    
                    //try and construct a UIImage:
                    if let imageData = response.data, let imageToCache = UIImage(data: imageData) {
                        completion(imageToCache, nil)
                        return
                    }
                    else {
                        let error = NSError(domain: "VWImageView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not construct UIImage"])
                        completion(nil, error)
                        return
                    }
                    
                case .failure(let error):
                    print(error)
                    completion(nil, error)
                    return
                }
            }
        }
    }
}
