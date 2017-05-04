//
//  MITNoteCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/18/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

protocol MITNoteCellDelegate: class
{
    func noteCell(_ noteCell: MITNoteCell, handleOptions sender: BouncingButton)
}

class MITNoteCell: BouncingTableViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var noteTextLabel: UILabel!
    
    weak var delegate: MITNoteCellDelegate?
    
    var note: Note? {
        didSet {
            self.noteTextLabel.text = note?.text
        }
    }
    
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
        self.delegate?.noteCell(self, handleOptions: sender)
    }
}
