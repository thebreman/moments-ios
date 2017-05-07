//
//  BouncingCollectionViewCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/7/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class BouncingCollectionViewCell: UICollectionViewCell
{
    var isSelectable = true
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if newValue {
                super.isHighlighted = true
                self.touchDown()
            }
            else if newValue == false {
                super.isHighlighted = false
                self.touchUp()
            }
        }
    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            if newValue {
                super.isSelected = true
                if self.isSelectable { self.touchDown() }
            }
            else if newValue == false {
                super.isSelected = false
                if self.isSelectable { self.touchUp() }
            }
        }
    }
}
