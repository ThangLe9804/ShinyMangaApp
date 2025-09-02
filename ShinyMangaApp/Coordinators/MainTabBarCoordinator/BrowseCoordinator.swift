//
//  BrowseCoordinator.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 2/7/25.
//

import UIKit
import SwiftUI

final class BrowseCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let browseView = PlaceholderView(title: "Browse placeholder")
        let browseHostingController = UIHostingController(rootView: browseView)
        navigationController.pushViewController(browseHostingController, animated: true)
    }
}
