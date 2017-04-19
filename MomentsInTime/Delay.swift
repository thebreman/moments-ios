//
//  Delay.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

func wait(seconds: Double, then closure: @escaping () -> Void)
{
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        closure()
    }
}
