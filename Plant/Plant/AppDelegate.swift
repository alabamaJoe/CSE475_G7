//
//  AppDelegate.swift
//  Plant
//
//  Created by Michael Park on 4/22/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import UIKit
import AWSCognito
import AWSCore
import AWSS3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let identityID = "us-west-2:1b040d1e-1467-4c13-9e3e-36ed39b53385"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //Setup credentials, see your awsconfiguration.json for the "YOUR-IDENTITY-POOL-ID"
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: identityID)

        //Setup the service configuration
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }


}

