//
//  HowToLearnApp.swift
//  HowToLearn
//
//  Created by How on 6/5/24.
//

import SwiftUI
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Set Messaging delegate
        Messaging.messaging().delegate = self
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission not granted: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    // Handle device token registration with FCM
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Handle foreground notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification response
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let urlString = userInfo["url"] as? String, let url = URL(string: urlString) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didReceiveDeepLink, object: url)
            }
        }
        completionHandler()
    }
    
    // Handle FCM messages
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token added)")
        // TODO: If necessary, send the token to your server.
    }
}

extension Notification.Name {
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")
}




@main
struct HowToLearnApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firestoreManager = FirestoreManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(firestoreManager)
                .onAppear {
                    AuthManager.shared.signInAnonymously()
                }
        }
    }
}
