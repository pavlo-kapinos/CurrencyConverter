//
//  AppDelegate.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 01.04.2023.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let exchangeVC = ExchangeViewController(networkManager: NetworkManager(config: .default), // FakeNetworkManager(),
                                                accountsManager: AccountsManager(loadData: true))
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let navController = UINavigationController(rootViewController: exchangeVC)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }

}

