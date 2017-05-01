//
//  MITNoteCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/18/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class MITNoteCell: BouncingTableViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var noteTextLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
        
        self.selectionStyle = .none
        self.isSelectable = false
    }
    
    //MARK: Actions
    
    @IBAction func handleOptions(_ sender: BouncingButton)
    {
        print("handle note options")
    }
}
