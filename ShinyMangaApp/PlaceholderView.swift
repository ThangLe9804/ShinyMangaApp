//
//  PlaceholderView.swift
//  ShinyMangaApp
//
//  Created by Thang Le on 21/8/25.
//


import SwiftUI

struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "doc.text.image")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray.opacity(0.6))
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Subtitle
            Text("This page isn’t ready yet. Check back later!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.yellow))
    }
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderView(title: "preview")
    }
}

#Preview {
    PlaceholderView(title: "preview")
}
