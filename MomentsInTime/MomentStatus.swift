//
//  MomentStatus.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/12/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

let COPY_STATUS_LOCAL = "Private"
let COPY_STATUS_UPLOADING = "Uploading..."
let COPY_STATUS_UPLOAD_FAILED = "Upload Failed! Tap to Retry"
let COPY_STATUS_LIVE = "Live"

enum MomentStatus: Int
{
    case new
    case local
    case uploading
    case uploadFailed
    case processing //? not sure how to handle this case...
    case live
    
    var message: String? {
        switch self {
        case .local: return COPY_STATUS_LOCAL
        case .uploading: return COPY_STATUS_UPLOADING
        case .uploadFailed: return COPY_STATUS_UPLOAD_FAILED
        case .live: return COPY_STATUS_LIVE
        default: return nil
        }
    }
    
    var color: UIColor? {
        switch self {
        case .local: return UIColor.mitOrange
        case .uploading: return UIColor.mitActionblue
        case .uploadFailed: return UIColor.mitRed
        case .live: return UIColor.mitGreen
        default: return nil
        }
    }
}
