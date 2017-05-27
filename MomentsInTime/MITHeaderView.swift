//
//  MITHeaderView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/27/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

protocol MITHeaderViewDelegate: class
{
    func handleClose(forWelcomeHeaderView welcomeView: MITHeaderView)
}

class MITHeaderView: UIView
{
    private let closeButton: BouncingButton = {
        let button = BouncingButton(type: .system)
        button.setImage(UIImage(named: "cancel-1"), for: .normal)
        button.adjustsImageWhenHighlighted = false
        button.showsTouchWhenHighlighted = false
        button.tintColor = UIColor.mitActionblue
        button.reversesTitleShadowWhenHighlighted = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.autoSetDimensions(to: CGSize(width: 24, height: 24))
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return button
    }()
    
    weak var headerDelegate: MITHeaderViewDelegate?
    
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
    
    @objc private func handleClose()
    {
        self.headerDelegate?.handleClose(forWelcomeHeaderView: self)
    }
    
    //MARK: Private
    
    func setup()
    {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.closeButton)

        self.closeButton.autoPinEdge(toSuperviewEdge: .top, withInset: 12.0)
        self.closeButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 12.0)
    }
}
