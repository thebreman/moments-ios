//
//  ScrollViews.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/27/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

extension UIScrollView
{
    func scrollToBottom(animated: Bool)
    {
        // find out the height of the content that is not visible in the scrollview
        // so it will just be the total content height - the height of the scrollView itself + any extra inset padding
        let offScreenScrollableContentHeight = self.contentSize.height - self.bounds.height + self.contentInset.bottom
        
        // get the top of the scrollView - usually this would be 0, but we need to account for any inset
        // maybe the nav bar perhaps
        let top = -self.contentInset.top
        
        // get the max so that if the content is smaller than the scrollView we dont muck around with things
        // we only want to scroll to bottom if we have to
        let delta = max(top, offScreenScrollableContentHeight)
        
        let bottomOffset = CGPoint(x: 0, y: delta);
        self.setContentOffset(bottomOffset, animated: animated)
    }
}
