//
//  GameItemViews.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Swimming Fish View
struct SwimmingFishView: View {
  let fish: SwimmingFish

  var body: some View {
    Text(fish.emoji)
      .font(.system(size: fish.size))
      .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
      .shadow(color: .black.opacity(0.3), radius: 2)
  }
}

// MARK: - Lootbox View
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

// MARK: - Shapes
struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
    return path
  }
}
