//
//  AppDelegate.swift
//  MomentsInTime
//
//  Created by Brian on 3/20/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import AVFoundation
import FacebookCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        //Configure Audio Session to have playback behavior (this is expected for media playback app):
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        }
        catch let error {
            print("Setting category to AVAudioSessionCategoryPlayback failed: \(error).")
        }
        
        //Facebook, Track App Installs and App Opens:
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
    {
        //reconnect sessions and store completion handlers so we can call them when the respective task finishes:
        if BackgroundUploadSessionManager.shared.session.configuration.identifier == identifier {
            BackgroundUploadSessionManager.shared.systemCompletionHandler = completionHandler
        }
        else if BackgroundUploadCompleteSessionManager.shared.session.configuration.identifier == identifier {
            BackgroundUploadCompleteSessionManager.shared.systemCompletionHandler = completionHandler
        }
        else if BackgroundUploadVideoMetadataSessionManager.shared.session.configuration.identifier == identifier {
            BackgroundUploadVideoMetadataSessionManager.shared.systemCompletionHandler = completionHandler
        }
        else {
            assert(false, "background ids didn't match")
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    {
        return SDKApplicationDelegate.shared.application(app, open: url, options: options)
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        //Facebook, Track App Installs and App Opens:
        AppEventsLogger.activate()
    }
}

