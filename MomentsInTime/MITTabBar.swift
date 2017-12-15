//
//  MITTabBar.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

@IBDesignable
class MITTabBar: UITabBar
{
    private let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.23)
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
    
    /**
     * add a separator line in the middle of the tab bar, separating the 2 tabs
     */
    private func setup()
    {
        self.addSubview(self.separatorView)
        
        self.separatorView.autoCenterInSuperview()
        self.separatorView.autoSetDimension(ALDimension.width, toSize: 1)
        self.separatorView.autoPinEdge(toSuperviewEdge: ALEdge.top, withInset: 8)
        
        if #available(iOS 11.0, *) {
            self.separatorView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
        else {
            self.separatorView.autoPinEdge(toSuperviewEdge: ALEdge.bottom, withInset: 8)
        }
    }
}
