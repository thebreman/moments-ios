//
//  Views.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

extension UIView
{
    func addContraints(withFormat format: String, views: UIView...)
    {
        var viewsDictionary = [String: UIView]()
        
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func touchUp()
    {
        self.animate(touchDown: false, completion: nil)
    }
    
    func touchDown()
    {
        self.animate(touchDown: true, completion: nil)
    }
    
    func animate(touchDown: Bool, completion: (()->Void)?)
    {
        let damping : CGFloat = (touchDown) ? 1 : 0.34
        let velocity : CGFloat = (touchDown) ? 0.5 : 0.8
        let duration : Double = (touchDown) ? 0.24 : 0.42
        let options : UIViewAnimationOptions = [.curveEaseOut, .beginFromCurrentState]
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: options, animations: {
            self.layer.transform = (touchDown) ? CATransform3DMakeScale(0.96, 0.96, 1) : CATransform3DIdentity
        }) { (done) in
            if done { completion?() }
        }
    }
    
    func roundCorners()
    {
        self.layer.cornerRadius = 4
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat)
    {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    func drawShadow(withOffset offset: CGSize)
    {
        self.layer.shadowOffset = offset
        self.layer.shadowColor = UIColor.mitShadow.cgColor
        self.layer.shadowRadius = 1.5
        self.layer.shadowOpacity = 0.40
        self.layer.shouldRasterize = true
        
        //scale matters so you dont render a non retina layer on a retina device
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    func drawShadow()
    {
        self.drawShadow(withOffset: CGSize(width: 1.0, height: 1.0))
    }
    
    // shadowPath is very fast but does not resize even with autolayout
    // dont set the path in vc, just subclass view and in layoutSubviews redraw the shadowPath
    func rasterizeShadow()
    {
        self.layer.shadowPath = UIBezierPath(roundedRect: self.layer.bounds, cornerRadius: self.layer.cornerRadius).cgPath
    }
}

