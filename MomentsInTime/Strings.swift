//
//  Strings.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 6/12/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//


import Foundation

extension String
{
    func trimmed() -> String
    {
        let spaces = CharacterSet.whitespacesAndNewlines
        let trimmed =  self.trimmingCharacters(in: spaces) //just remove from leading and trailing (not anything in th middle)
        return trimmed
    }
}
