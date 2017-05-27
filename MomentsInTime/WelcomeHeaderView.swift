//
//  WelcomeHeaderView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

//delegate for optional accessoryView to be displayed every nth cell (n is frequency):
protocol WelcomeHeaderViewDelegate: class
{
    func handleAction(forWelcomeHeaderView welcomeView: WelcomeHeaderView)
    func handleClose(forWelcomeHeaderView welcomeView: WelcomeHeaderView)
}

class WelcomeHeaderView: UIView
{
    private let textActionView: MITTextActionView = {
        let textView = MITTextActionView.mitWelcomeView()
        textView.actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        return textView
    }()
    
    private let closeButton: BouncingButton = {
        let button = BouncingButton(type: .system)
        button.setImage(UIImage(named: "cancel-1"), for: .normal)
        button.adjustsImageWhenHighlighted = false
        button.showsTouchWhenHighlighted = false
        button.tintColor = UIColor.mitActionblue
        button.reversesTitleShadowWhenHighlighted = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.autoSetDimensions(to: CGSize(width: 20, height: 20))
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return button
    }()
    
    weak var delegate: WelcomeHeaderViewDelegate?
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    //MARK: Actions
    
    @objc private func handleAction()
    {
        self.delegate?.handleAction(forWelcomeHeaderView: self)
    }
    
    @objc private func handleClose()
    {
        self.delegate?.handleClose(forWelcomeHeaderView: self)
    }
    
    //MARK: Private
    
    private func setup()
    {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.textActionView)
        self.addSubview(self.closeButton)
        
        self.textActionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 20, left: 0, bottom: 24, right: 0))
        self.textActionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 144).isActive = true
        self.closeButton.autoPinEdge(toSuperviewEdge: .top, withInset: 12.0)
        self.closeButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 12.0)
    }
}
