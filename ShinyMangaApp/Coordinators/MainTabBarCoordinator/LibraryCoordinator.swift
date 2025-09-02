//
//  LibraryCoordinator.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 2/7/25.
//

import SwiftUI
import UIKit

final class LibraryCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let browseView = PlaceholderView(title: "library placeholder")
        let browseHostingController = UIHostingController(rootView: browseView)
        navigationController.pushViewController(browseHostingController, animated: true)
    }
}
