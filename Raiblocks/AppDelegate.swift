//
//  AppDelegate.swift
//  Nano
//
//  Created by Zack Shapiro on 11/22/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit

import Crashlytics
import Fabric
import RealmSwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var navigationController: UINavigationController?
    var window: UIWindow?

    private var coverWindow: UIWindow?
    private var coverVC: UIViewController?

    var appBackgroundingForSeedOrSend: Bool = false

    // TODO: Before deploy, make sure this is set to nil/false
    let devConfig: (device: Device?, skipLegal: Bool) = (nil, false)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let currentSchemaVersion: UInt64 = 2
        let config = Realm.Configuration(encryptionKey: UserService.getKeychainKeyID() as Data, readOnly: false, schemaVersion: currentSchemaVersion)
        Realm.Configuration.defaultConfiguration = config

        Connectivity.shared.startNetworkConnectivityObserver()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "LogOut"), object: nil, queue: nil) { _ in
            UserService.logOut()

            AnalyticsEvent.logOut.track()

            DispatchQueue.main.async {
                self.navigationController?.setViewControllers([WelcomeViewController()], animated: false)
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }

        if let _ = UserService().currentUserSeed() {
            self.navigationController = UINavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel()))
        } else {
            self.navigationController = UINavigationController(rootViewController: WelcomeViewController())
        }

        // For on-device testing when you don't have all the devices, just make sure you're using a configuration smaller than your actual device size (options: .se, .regular, .plus, .x)
        window = UIWindow(frame: devConfig.device?.frame ?? UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        if let credentials = UserService().fetchCredentials() {
            if credentials.hasAgreedToTracking || !credentials.hasAnsweredAnalyticsQuestion {
                // The latter for if the user has credentials but hasn't answered yet, primarily for legal agreement event recording
                AnalyticsService.start()
            }
        } else {
            // Begin tracking for legal agreement event recording
            AnalyticsService.start()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        guard !appBackgroundingForSeedOrSend else { return }

        coverVC = BackgroundViewController()
        coverWindow = UIWindow(frame: UIScreen.main.bounds)
        let existingTopWindow = UIApplication.shared.windows.last

        coverWindow?.windowLevel = existingTopWindow!.windowLevel + 1
        coverVC!.view.frame = coverWindow!.bounds
        coverWindow?.rootViewController = coverVC
        coverWindow?.makeKeyAndVisible()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "ReestablishConnection")))

        if coverWindow != nil && !appBackgroundingForSeedOrSend {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.coverVC?.view.alpha = 0
            }) { _ in
                self.coverWindow!.isHidden = true
                self.coverWindow!.rootViewController = nil
                self.coverWindow = nil
                self.coverVC = nil
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
