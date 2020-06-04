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
import BackgroundTasks
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {(granted, error) in
           // Use granted to check if permission is granted
        }
        return true
    }
    
//    private func handleAppRefresh(_ task: BGTask) {
//        let queue = OperationQueue()
//
//        queue.maxConcurrentOperationCount = 1
////        let appRefreshOperation =  DataLoader.loadJSON()
////        queue.addOperation(appRefreshOperation)
//
//        task.expirationHandler = {
//            queue.cancelAllOperations()
//        }
//
//        let lastOperation = queue.operations.last
//        lastOperation?.completionBlock = {
//            task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
//        }
//
//        scheduleAppRefresh()
//    }
    
//    func applicationDidEnterBackground(_ application: UIApplication) {
//        scheduleAppRefresh()
//    }
//
//    private func scheduleAppRefresh() {
//        do {
//            let request = BGAppRefreshTaskRequest(identifier: "com.jsonData.refresh")
//            request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
//            try BGTaskScheduler.shared.submit(request)
//        } catch {
//            print(error)
//        }
//    }
//
    

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
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
    
//    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () ->Void){
//        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
//    }
 

}

