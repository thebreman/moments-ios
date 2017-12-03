//
//  ProfileImageView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/28/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

private let WIDTH_IMAGE_VIEW: CGFloat = 80

class ProfileImageView: UIView
{
    var profileImage: UIImage? {
        didSet {
            if let newImage = self.profileImage {
                self.imageView.setImageAnimated(newImage)
            }
        }
    }
    
    var actionButton: BouncingButton = {
        let button = BouncingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .center
        button.isEnabled = true
        return button
    }()
    
    @objc dynamic var actionFont: UIFont? {
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
    
    private var imageView: MITCircleImageView = {
        let view = MITCircleImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.image = #imageLiteral(resourceName: "interviewee_placeholder")
        view.clipsToBounds = true
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    private func setup()
    {
        self.addSubview(self.containerView)
        self.containerView.addSubview(self.imageView)
        self.containerView.addSubview(self.actionButton)
        
        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) { 
            self.imageView.autoSetDimension(.height, toSize: WIDTH_IMAGE_VIEW)
            self.imageView.autoSetDimension(.width, toSize: WIDTH_IMAGE_VIEW)
        }
        
        self.imageView.layer.cornerRadius = WIDTH_IMAGE_VIEW / 2
        self.imageView.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor).isActive = true
        self.actionButton.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor).isActive = true
        
        self.containerView.addContraints(withFormat: "H:|->=0-[v0]->=0-|", views: self.actionButton)
        self.containerView.addContraints(withFormat: "V:|-12-[v0]-4-[v1]-4-|", views: self.imageView, self.actionButton)
        self.containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.addContraints(withFormat: "V:|[v0]|", views: self.containerView)
        self.addContraints(withFormat: "H:|->=20-[v0]->=20-|", views: self.containerView)
    }
}
