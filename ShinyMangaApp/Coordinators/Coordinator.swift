//
//  Coordinator.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 23/6/25.
//

import UIKit

protocol Coordinator {
  var childCoordinators: [Coordinator] { get set }
  var navigationController: UINavigationController { get set }

  func start()
}
