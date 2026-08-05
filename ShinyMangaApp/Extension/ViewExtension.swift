//
//  ViewExtension.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 16/8/25.
//

import SwiftUI

extension View {
    func debugBorder(_ color: Color = randomColorProvider(), width: CGFloat = 1) -> some View {
        self.overlay(RoundedRectangle(cornerRadius: 1).stroke(color, lineWidth: width))
    }
}

func randomColorProvider() -> Color {
    let colors = [Color.red, Color.yellow, Color.blue, Color.orange, Color.green, Color.brown]
    let random = Int.random(in: 0 ..< 6)
    return colors[random]
}
