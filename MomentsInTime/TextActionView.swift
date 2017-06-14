//
//  TextActionView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/16/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

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
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
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
    
    //    override func layoutSubviews()
    //    {
    //        let labelHorizontalInset: CGFloat = 40.0
    //        self.titleLabel.preferredMaxLayoutWidth = self.bounds.width - (labelHorizontalInset * 2)
    //        self.messageLabel.preferredMaxLayoutWidth = self.bounds.width - (labelHorizontalInset * 2)
    //
    //        super.layoutSubviews()
    //    }
    
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
        self.containerView.addContraints(withFormat: "V:|-4-[v0]-8-[v1]-4-[v2]|", views: self.titleLabel, self.messageLabel, self.actionButton)
        self.containerView.addContraints(withFormat: "H:|[v0]|", views: self.titleLabel)
        self.containerView.addContraints(withFormat: "H:|[v0]|", views: self.messageLabel)
        self.containerView.addContraints(withFormat: "H:|->=0-[v0]->=0-|", views: self.actionButton)
        self.actionButton.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor).isActive = true
        
        self.containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        //self.containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        //pin the containerView to our edges:
        //The above centering constraints should be enough to get the look we want (this is true),
        //however, in order for out actionButton to receive touch events, we need to make sure the top and bottom edges
        //are being pushed on so that we have a height:
        self.addContraints(withFormat: "V:|[v0]|", views: self.containerView)
        self.addContraints(withFormat: "H:|-40-[v0]-40-|", views: self.containerView)
    }
}

