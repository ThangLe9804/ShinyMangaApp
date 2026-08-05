//
//  AppTheme.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 1/9/25.
//

import UIKit
import SwiftUI

struct TabBarTheme {
    let backgroundColor: UIColor
    let selectedTintColor: UIColor
    let unselectedTintColor: UIColor
}

enum AppTheme {
    static let dark = TabBarTheme(
        backgroundColor: .accentPrimary,
        selectedTintColor: .textPrimary,
        unselectedTintColor: .textSecondary
    )
}
