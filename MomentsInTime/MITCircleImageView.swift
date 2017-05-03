//
//  MITCircleImageView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/29/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class MITCircleImageView: UIImageView
{
    func loadImageFromDisk(withUrlString urlString: String)
    {
        if let imageURL = URL(string: urlString),
            let imageData = try? Data.init(contentsOf: imageURL, options: []) {
            self.image = UIImage(data: imageData)
        }
    }
    
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
