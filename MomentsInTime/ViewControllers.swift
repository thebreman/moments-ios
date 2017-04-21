//
//  ViewControllers.swift
//  VideoWonderland
//
//  Created by Andrew Ferrarone on 3/25/17.
//  Copyright © 2017 Andrew Ferrarone. All rights reserved.
//

import UIKit

extension UIViewController
{
    //I like to use this in prepareForSegue, so we don't have to check if we are inside of a NavController:
    var contentViewController: UIViewController {
        if let navCon = self as? UINavigationController {
            return navCon.visibleViewController ?? self
        } else {
            return self
        }
    }
}
