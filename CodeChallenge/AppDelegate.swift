//
//  AppDelegate.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/27/16.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if NSClassFromString("XCTest") != nil {
            // Running tests, prevent UI from loading and concurring
            window?.rootViewController = UIViewController()
        } else {
            let viewController = MoviesListViewController(uiTesting: CommandLine.arguments.contains("--uitesting"))
            window?.rootViewController = UINavigationController(rootViewController: viewController)
        }
        window?.makeKeyAndVisible()
        
        return true
    }
}
