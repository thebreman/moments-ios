//
//  MITActiveLinkCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/18/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import ActiveLabel

class MITActiveLinkCell: ActiveLinkCell
{
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.setup()
    }
    
    private func setup()
    {
        self.activeLabel.customize { label in
            
            let customInterviewType = ActiveType.custom(pattern: "Select a special person to interview")
            label.customColor[customInterviewType] = UIColor.mitActionblue
            
            let customNoteType = ActiveType.custom(pattern: "Add a new note")
            label.customColor[customNoteType] = UIColor.mitActionblue
            
            label.enabledTypes = [customInterviewType, customNoteType]
            
            label.handleCustomTap(for: customInterviewType) { element in
                print("handle custom interview type tapped: \(element)")
            }
            
            label.handleCustomTap(for: customNoteType) { element in
                print("handle custom note type tapped: \(element)")
            }
            
            label.text = "Select a special person to interview"
        }
    }
}



