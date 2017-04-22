//
//  FetchView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

class FetchingView: UIView
{
    var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
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
        self.addSubview(self.spinner)
        self.spinner.autoCenterInSuperview()
    }
}

class FetchView: UIView
{
    let fetchingView = FetchingView()
    
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
    
    var shouldAnimate = false {
        didSet {
            self.shouldAnimate ? self.fetchingView.spinner.startAnimating() : self.fetchingView.spinner.stopAnimating()
        }
    }
    
    private func setup()
    {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.fetchingView)
        self.fetchingView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 60, left: 0, bottom: 60, right: 0))
    }
}
