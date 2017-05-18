//
//  TableViews.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/3/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

extension UITableView
{
    /**
     * IMPORTANT: if you are going to do more than one of these updates consecutively
     * You can't use these methods, you need to do every update inside begin/end updates...
     */
    
    func refreshRows(forIndexPaths paths: [IndexPath])
    {
        self.beginUpdates()
        self.reloadRows(at: paths, with: .fade)
        self.endUpdates()
    }
    
    func refreshSections(_ sections: Int...)
    {
        self.beginUpdates()
        self.reloadSections(IndexSet(sections), with: .automatic)
        self.endUpdates()
    }
    
    func updateRows(forIndexPaths paths: [IndexPath])
    {
        self.beginUpdates()
        self.deleteRows(at: paths, with: .right)
        self.insertRows(at: paths, with: .left)
        self.endUpdates()
    }
    
    func insertNewRows(forIndexPaths paths: [IndexPath])
    {
        self.beginUpdates()
        self.insertRows(at: paths, with: .middle)
        self.endUpdates()
    }
    
    func removeRows(forIndexPaths paths: [IndexPath])
    {
        self.beginUpdates()
        self.deleteRows(at: paths, with: .fade)
        self.endUpdates()
    }
}
