//
//  CameraMan.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/21/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

extension PHPhotoLibrary
{
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    class func verifyAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        switch PHPhotoLibrary.authorizationStatus() {
        
        case .authorized:
            authorizedHandler()
        
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { authorizationStatus in
                
                guard authorizationStatus == .authorized else {
                    
                    //do nothing first time denied:
                    return
                }
                
                authorizedHandler()
            }
            
        default:
            notAuthorizedHandler()
        }
    }
}

extension AVCaptureDevice
{
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    class func verifyVideoAndAudioAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        //first verify camera authorization:
        //only proceed to audio verification if we have camera authorized:
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        
        case .authorized:
            
            //granted, now check for microphone authorization:
            AVCaptureDevice.verifyAudioAuthorization(authorizedHandler: authorizedHandler, notAuthorizedHandler: notAuthorizedHandler)
        
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                
                guard granted == true else {
                    
                    //do nothing first time denied:
                    return
                }
                
                //granted, now check for microphone authorization:
                AVCaptureDevice.verifyAudioAuthorization(authorizedHandler: authorizedHandler, notAuthorizedHandler: notAuthorizedHandler)
            }
        
        default:
            notAuthorizedHandler()
        }
    }
    
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    class func verifyVideoAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            
        case .authorized:
            authorizedHandler()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                
                guard granted == true else {
                    
                    //do nothing first time denied:
                    return
                }
                authorizedHandler()
            }
            
        default:
            notAuthorizedHandler()
        }
    }
    
    /**
     * Upon first authorization request, if user denies permission we do not call notAuthorizedHandler.
     * Since they just denied, nothing will happen and this seems appropriate/ expected.
     * every time after, the notAuthorizedHandler will be called if authorization is denied or restricted:
     */
    private class func verifyAudioAuthorization(authorizedHandler: @escaping () -> Void, notAuthorizedHandler: @escaping () -> Void)
    {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) {
            
        case .authorized:
            authorizedHandler()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio) { granted in
                
                guard granted == true else {
                    
                    //do nothing first time denied:
                    return
                }
                authorizedHandler()
            }
            
        default:
            notAuthorizedHandler()
        }
    }
}
