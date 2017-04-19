//
//  MITNoteCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/18/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class MITNoteCell: UITableViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var noteTextLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
    }
    
    //MARK: Actions
    @IBAction func handleOptions(_ sender: BouncingButton)
    {
        print("handle note options")
    }
    
    //MARK: Utilities:
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        selected ? self.touchDown() : self.touchUp()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool)
    {
        super.setHighlighted(highlighted, animated: animated)
        highlighted ? self.touchDown() : self.touchUp()
    }
}
