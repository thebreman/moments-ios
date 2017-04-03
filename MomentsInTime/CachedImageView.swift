//
//  CachedImageView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import SDWebImage

class CachedImageView: UIImageView
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
    
    private func setup()
    {
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
    
    func loadImageFromCache(withUrlString urlString: String)
    {
        if let imageURL = URL(string: urlString) {
            self.sd_setImage(with: imageURL)
        }
    }
}
