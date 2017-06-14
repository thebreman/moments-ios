//
//  Pulsor.swift
//  Index
//
//  Created by Brian on 3/26/17.
//  Copyright © 2017 BrianCoxCompany. All rights reserved.
//

import UIKit
import Pulsator
import PureLayout

class Pulsar: UIView
{
    private lazy var pulsator : Pulsator = {
        let pulsator = Pulsator()
        pulsator.radius = 64
        pulsator.animationDuration = 3.0
        pulsator.numPulse = 2
        pulsator.backgroundColor = UIColor.mitActionblue.cgColor
        return pulsator
    }()
    
    private lazy var containerView : UIView = {
        let pulseContainer = UIView()
        pulseContainer.layer.addSublayer(self.pulsator)
        return pulseContainer
    }()
    
    private var allConstraints = [NSLayoutConstraint]()
    
    override func willMove(toSuperview newSuperview: UIView?)
    {
        self.layer.addSublayer(self.pulsator)
    }
    
    func showAlertFrom(_ superview: UIView, centeredOn centerView: UIView, manualOffset: UIEdgeInsets = UIEdgeInsets())
    {
        self.stop()
        
        superview.addSubview(self)
        
        let leftRightOffset = manualOffset.left - manualOffset.right
        let topBottomOffset = manualOffset.top - manualOffset.bottom
        
        self.allConstraints.append(self.autoAlignAxis(ALAxis.vertical, toSameAxisOf: centerView, withOffset: leftRightOffset))
        self.allConstraints.append(self.autoAlignAxis(ALAxis.horizontal, toSameAxisOf: centerView, withOffset: topBottomOffset))
        self.layoutIfNeeded()
        
        self.pulsator.start()
    }
    
    func stop()
    {
        self.pulsator.stop()
        self.containerView.removeConstraints(self.allConstraints)
        self.removeFromSuperview()
    }
    
}
