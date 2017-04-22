//
//  AppDelegate.swift
//  MomentsInTime
//
//  Created by Brian on 3/20/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import AVFoundation

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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

