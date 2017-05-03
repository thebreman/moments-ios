//
//  ImageViews.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/1/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

extension UIImageView
{
    func setImageAnimated(_ image: UIImage?)
    {
        UIView.transition(with: self, duration: 0.25, options: UIViewAnimationOptions.transitionFlipFromTop, animations: {
            self.image = image
        }, completion: nil)
    }
}
