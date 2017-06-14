//
//  TextActionView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/16/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

class TextActionView: UIView
{
    //MARK: Public
    //dynamic properties allow for UIAppearance proxy support
    
    var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
        
    }
    
    dynamic var titleFont: UIFont? {
        get {
            return self.titleLabel.font
        }
        set {
            self.titleLabel.font = newValue
        }
    }
    
    var titleColor: UIColor? {
        get {
            return self.titleLabel.textColor
        }
        set {
            self.titleLabel.textColor = newValue
        }
    }
    
    var message: String? {
        get {
            return self.messageLabel.text
        }
        set {
            self.messageLabel.text = newValue
        }
    }
    
    dynamic var messageFont: UIFont? {
        get {
            return self.messageLabel.font
        }
        set {
            self.messageLabel.font = newValue
        }
    }
    
    var messageColor: UIColor? {
        get {
            return self.messageLabel.textColor
        }
        set {
            self.messageLabel.textColor = newValue
        }
    }
    
    var actionButton: BouncingButton = {
        let button = BouncingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .center
        button.isEnabled = true
        return button
    }()
    
    dynamic var actionFont: UIFont? {
        get {
            return self.actionButton.titleLabel?.font
        }
        set {
            self.actionButton.titleLabel?.font = newValue
        }
    }
    
    func setActionColor(_ color: UIColor, forState state: UIControlState)
    {
        self.actionButton.setTitleColor(color, for: state)
    }
    
    //MARK: Private
    
    private let containerView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
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
    
    func setup()
    {
        //add container:
        self.addSubview(self.containerView)
        
        //add items to container:
        self.containerView.addSubview(self.titleLabel)
        self.containerView.addSubview(self.messageLabel)
        self.containerView.addSubview(self.actionButton)
        
        self.setupConstraints()
    }
    
    private func setupConstraints()
    {
        //configure everything inside of containerView:
        self.containerView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 8, bottom: 8, right: 4))
        
        self.titleLabel.autoPinEdge(ALEdge.bottom, to: ALEdge.top, of: self.messageLabel, withOffset: -8)
        self.titleLabel.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        
        self.messageLabel.autoCenterInSuperview()
        self.messageLabel.autoPinEdge(toSuperviewEdge: ALEdge.left, withInset: 8)
        self.messageLabel.autoPinEdge(toSuperviewEdge: ALEdge.right, withInset: 8)
        
        self.actionButton.autoPinEdge(ALEdge.top, to: ALEdge.bottom, of: self.messageLabel, withOffset: 8)
        self.actionButton.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
    }
}

