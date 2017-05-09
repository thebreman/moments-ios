//
//  BlinkingView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/8/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

class BlinkingView: UIView
{
    private lazy var circle: UIView! = {
        let view = UIView()
        view.backgroundColor = UIColor.mitActionblue
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        view.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        view.layer.cornerRadius = view.frame.size.width / 2
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var blinkingAnimation: CABasicAnimation = {
        let blinkingAnimation = CABasicAnimation(keyPath: "transform.scale")
        blinkingAnimation.fromValue = self.circleGrowScale
        blinkingAnimation.toValue = self.blinkingScale
        blinkingAnimation.duration = 0.5
        blinkingAnimation.autoreverses = true
        blinkingAnimation.repeatCount = .infinity
        blinkingAnimation.fillMode = kCAFillModeForwards
        blinkingAnimation.isRemovedOnCompletion = false
        blinkingAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        return blinkingAnimation
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
    
    //MARK: Public
    
    var circleGrowScale: CGFloat = 11
    var blinkingScale: CGFloat = 6
    
    func startBlinking()
    {
        self.circle.layer.add(self.blinkingAnimation, forKey: "blinking")
    }
    
    func stopBlinking()
    {
        self.circle.layer.removeAllAnimations()
    }
    
    //MARK: Utilities
    
    private func setup()
    {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .clear
        self.addSubview(self.circle)
        
        //animate circle to large size before blinking starts:
        UIView.animate(withDuration: 0.5) { 
            self.circle.transform = (CGAffineTransform(scaleX: self.circleGrowScale, y: self.circleGrowScale))
        }
    }
}
