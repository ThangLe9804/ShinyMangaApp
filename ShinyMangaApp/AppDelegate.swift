//
//  AppDelegate.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 22/4/25.
//

import SwiftUI
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let mainTabBarController = UITabBarController()
            configure(tabBarController: mainTabBarController, with: AppTheme.dark)

            let mainCoordinator = MainCoordinator(tabBarController: mainTabBarController)
            mainCoordinator.start()
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = mainCoordinator.tabBarController
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func configure(tabBarController: UITabBarController, with theme: TabBarTheme) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.backgroundColor

        appearance.stackedLayoutAppearance.selected.iconColor = theme.selectedTintColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: theme.selectedTintColor]

        appearance.stackedLayoutAppearance.normal.iconColor = theme.unselectedTintColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: theme.unselectedTintColor]

        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
    }
}
