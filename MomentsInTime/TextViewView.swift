//
//  TextViewView.swift
//  
//
//  Created by Andrew Ferrarone on 4/28/17.
//
//

import UIKit
import PureLayout

class TextViewView: UIView
{
    var textView = UITextView()
    
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
        self.addSubview(self.textView)
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 8))
    }
}
