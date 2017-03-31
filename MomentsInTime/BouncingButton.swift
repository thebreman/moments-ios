//
//  BouncingButton.swift
//  VideoWonderland
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Andrew Ferrarone. All rights reserved.
//

import UIKit

class BouncingButton: UIButton
{
    override var isHighlighted : Bool {
        didSet {
            isHighlighted ? self.touchDown() : self.touchUp()
        }
    }
}
