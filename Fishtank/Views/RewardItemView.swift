//
//  RewardItemView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct RewardItemView: View {
  let fish: CollectedFish
  let isSelected: Bool
  @State private var starRotation: Double = 0

  var body: some View {
    ZStack(alignment: .topTrailing) {
      // Main fish display
      VStack(spacing: 5) {
        Image(fish.imageName)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: 65, height: 35)

        Text(fish.name)
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .lineLimit(1)

        Text(fish.rarity.rawValue)
          .font(.caption2)
          .fontWeight(.light)
          .foregroundColor(fish.rarity.color)
          .lineLimit(1)
      }
      .padding(8)
      .frame(width: 80)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(fish.rarity.color.opacity(0.2))
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .stroke(
                fish.rarity.color.opacity(isSelected ? 1.0 : 0.5), lineWidth: isSelected ? 3 : 1)
          )
      )
      .scaleEffect(isSelected ? 1.1 : 1.0)
      .shadow(
        color: isSelected ? fish.rarity.color.opacity(0.8) : .clear, radius: isSelected ? 10 : 0)
      
      // Gold star for shiny fish
      if fish.isShiny {
        Image(systemName: "star.fill")
          .font(.system(size: 16))
          .foregroundColor(.yellow)
          .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
          .rotationEffect(.degrees(starRotation))
          .animation(
            Animation.easeInOut(duration: 2)
              .repeatForever(autoreverses: false),
            value: starRotation
          )
          .onAppear {
            starRotation = 360
          }
          .padding(5)
      }
    }
  }
} 