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
    ZStack {
      Ellipse()
        .fill(fish.color)
        .frame(width: fish.size, height: fish.size * 0.6)

      Triangle()
        .fill(fish.color.opacity(0.8))
        .frame(width: fish.size * 0.4, height: fish.size * 0.4)
        .offset(x: fish.direction > 0 ? -fish.size * 0.4 : fish.size * 0.4)

      Circle()
        .fill(.white)
        .frame(width: fish.size * 0.2)
        .overlay(
          Circle()
            .fill(.black)
            .frame(width: fish.size * 0.1)
        )
        .offset(x: fish.direction > 0 ? fish.size * 0.15 : -fish.size * 0.15, y: -fish.size * 0.1)

      Text(fish.emoji)
        .font(.system(size: fish.size * 0.3))
        .offset(y: fish.size * 0.1)
    }
    .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
    .shadow(color: .black.opacity(0.3), radius: 2)
  }
}

// MARK: - Gift Box View
struct GiftBoxView: View {
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.brown)
        .frame(width: 40, height: 40)

      Rectangle()
        .fill(Color.red)
        .frame(width: 40, height: 6)

      Rectangle()
        .fill(Color.red)
        .frame(width: 6, height: 40)

      Text("🎀")
        .font(.title3)
        .offset(y: -20)
    }
    .scaleEffect(isAnimating ? 1.1 : 1.0)
    .animation(
      Animation.easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true),
      value: isAnimating
    )
    .onAppear {
      isAnimating = true
    }
    .shadow(color: .yellow.opacity(0.5), radius: 8)
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
