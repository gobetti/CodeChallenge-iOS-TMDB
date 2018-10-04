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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if NSClassFromString("XCTest") != nil {
            // Running tests, prevent UI from loading and concurring
            window?.rootViewController = UIViewController()
        } else {
            let viewModel = MoviesListViewModel(uiTesting: CommandLine.arguments.contains("--uitesting"))
            let viewController = MoviesListViewController(viewModel: viewModel)
            window?.rootViewController = UINavigationController(rootViewController: viewController)
        }
        window?.makeKeyAndVisible()
        
        return true
    }
}
