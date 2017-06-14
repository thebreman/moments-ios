//
//  ShareLiveMomentHeaderView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/27/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

class ShareLiveMomentHeaderView: MITHeaderView
{
    private let textActionView: MITTextActionView = {
        let textView = MITTextActionView.mitShareLiveMomentView()
        textView.actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        return textView
    }()
    
    //MARK: Actions
    
    @objc private func handleAction()
    {
        self.delegate?.handleAction(forHeaderView: self, sender: self.textActionView.actionButton)
    }
    
    //MARK: Private
    
    internal override func setup()
    {
        super.setup()
        
        self.addSubview(self.textActionView)
        self.textActionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 20, left: 0, bottom: 22, right: 0))
        self.textActionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
    }
}
