//
//  BouncingTableViewCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class BouncingTableViewCell: UITableViewCell
{
    var isSelectable = true
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool)
    {
        super.setHighlighted(highlighted, animated: animated)
        highlighted ? self.touchDown() : self.touchUp()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        if self.isSelectable {
            selected ? self.touchDown() : self.touchUp()
        }
    }
}
