//
//  MainCoordinator.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 23/6/25.
//

import UIKit

final class MainCoordinator {
    var childCoordinators: [Coordinator] = []
    var tabBarController: UITabBarController

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    func start() {
        let browseCoordinator = self.GetBrowseCoordinator()
        self.childCoordinators.append(browseCoordinator)

        let feedCoordinator = self.GetFeedCoordinator()
        self.childCoordinators.append(feedCoordinator)

        let libraryCoordinator = self.GetLibraryCoordinator()
        self.childCoordinators.append(libraryCoordinator)

        self.tabBarController.viewControllers = [
            browseCoordinator.navigationController,
            feedCoordinator.navigationController,
            libraryCoordinator.navigationController
        ]
    }

    func GetLibraryCoordinator() -> Coordinator {
        let libraryCoordinator = LibraryCoordinator(navigationController: UINavigationController())
        libraryCoordinator.start()
        libraryCoordinator.navigationController.tabBarItem = UITabBarItem(
            title: "About",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
        return libraryCoordinator
    }

    func GetFeedCoordinator() -> Coordinator {
        let feedCoordinator = FeedCoordinator(navigationController: UINavigationController())
        feedCoordinator.navigationController.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass.circle"),
            selectedImage: UIImage(systemName: "magnifyingglass.circle.fill")
        )
        feedCoordinator.start()
        return feedCoordinator
    }

    func GetBrowseCoordinator() -> Coordinator {
        let browseCoordinator = BrowseCoordinator(navigationController: UINavigationController())
        browseCoordinator.navigationController.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house.circle"),
            selectedImage: UIImage(systemName: "house.circle.fill")
        )
        browseCoordinator.start()
        return browseCoordinator
    }
}
