//
//  LootboxView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct LootboxView: View {
  let type: LootboxType
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .fill(type.color.opacity(0.8))
        .frame(width: 50, height: 50)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(type.color, lineWidth: 3)
        )

      Text(type.emoji)
        .font(.title)
    }
    .scaleEffect(isAnimating ? 1.15 : 1.0)
    .animation(
      Animation.easeInOut(duration: 0.8)
        .repeatForever(autoreverses: true),
      value: isAnimating
    )
    .onAppear {
      isAnimating = true
    }
    .shadow(color: type.color.opacity(0.7), radius: 10)
  }
} 