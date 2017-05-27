//
//  ShareLiveMomentHeaderView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/27/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

//delegate for optional accessoryView to be displayed every nth cell (n is frequency):
protocol ShareLiveMomentHeaderViewDelegate: class
{
    func handleAction(forShareLiveMomentHeaderView headerView: ShareLiveMomentHeaderView)
    func handleClose(forShareLiveMomentHeaderView headerView: ShareLiveMomentHeaderView)
}

class ShareLiveMomentHeaderView: MITHeaderView, MITHeaderViewDelegate
{
    private let textActionView: MITTextActionView = {
        let textView = MITTextActionView.mitShareLiveMomentView()
        textView.actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        return textView
    }()
    
    weak var delegate: ShareLiveMomentHeaderViewDelegate?
    
    //MARK: Actions
    
    @objc private func handleAction()
    {
        self.delegate?.handleAction(forShareLiveMomentHeaderView: self)
    }
    
    //MARK: MITHeaderViewDelegate
    
    func handleClose(forWelcomeHeaderView welcomeView: MITHeaderView)
    {
        self.delegate?.handleClose(forShareLiveMomentHeaderView: self)
    }
    
    //MARK: Private
    
    internal override func setup()
    {
        self.headerDelegate = self
        
        self.addSubview(self.textActionView)
        self.textActionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 20, left: 0, bottom: 22, right: 0))
        self.textActionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 144).isActive = true
    }
}
