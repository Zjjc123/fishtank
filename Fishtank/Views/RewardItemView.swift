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
  @State private var glowOpacity: Double = 0.3

  var body: some View {
    ZStack {
      // Glow effect for shiny fish
      if fish.isShiny {
        VStack(spacing: 5) {
          Image(fish.imageName)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: 65, height: 35)
            .blur(radius: 4)
            .foregroundColor(.yellow)
            .opacity(glowOpacity)
            .animation(
              Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
              value: glowOpacity
            )
            .onAppear {
              glowOpacity = 0.6
            }

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
      }
      
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
    }
  }
} 