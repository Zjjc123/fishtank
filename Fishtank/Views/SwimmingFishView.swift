//
//  SwimmingFishView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct SwimmingFishView: View {
  let fish: SwimmingFish
  @ObservedObject var fishTankManager: FishTankManager
  @State private var glowOpacity: Double = 0.2

  var body: some View {
    ZStack {
      // Glow effect for shiny fish
      if fish.collectedFish.isShiny {
        // Outer glow layer (largest, most diffused)
        Image(fish.imageName)
          .resizable()
          .renderingMode(.template)
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size * 1.5, height: fish.size * 1.5)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .blur(radius: 25)
          .foregroundColor(.yellow)
          .opacity(glowOpacity)

        // Middle glow layer
        Image(fish.imageName)
          .resizable()
          .renderingMode(.template)
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size * 1.3, height: fish.size * 1.3)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .blur(radius: 15)
          .foregroundColor(.yellow)
          .opacity(glowOpacity + 0.1)

        // Inner bright glow layer
        Image(fish.imageName)
          .resizable()
          .renderingMode(.template)
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size * 1.15, height: fish.size * 1.15)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .blur(radius: 8)
          .foregroundColor(.yellow)
          .opacity(glowOpacity + 0.2)
      }

      // Main fish image with yellow overlay for shiny fish
      ZStack {
        // Base fish image (only shown for non-shiny fish)
        if !fish.collectedFish.isShiny {
          Image(fish.imageName)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: fish.size, height: fish.size)
            .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
            .shadow(color: .black.opacity(0.3), radius: 2)
        }

        // Yellow fish (only for shiny fish)
        if fish.collectedFish.isShiny {
          // Base fish image
          Image(fish.imageName)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: fish.size, height: fish.size)
            .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
            .shadow(color: .black.opacity(0.3), radius: 2)

          // Yellow overlay
          Image(fish.imageName)
            .resizable()
            .renderingMode(.template)
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: fish.size, height: fish.size)
            .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
            .foregroundColor(.yellow)
            .blendMode(.overlay)
            .opacity(glowOpacity)

          // Bright yellow highlight
          Image(fish.imageName)
            .resizable()
            .renderingMode(.template)
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: fish.size, height: fish.size)
            .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
            .foregroundColor(.yellow)
            .blendMode(.plusLighter)
            .opacity(glowOpacity - 0.1)
        }
      }
      .animation(.interpolatingSpring(stiffness: 300, damping: 15), value: fish.direction)
      .animation(.easeInOut(duration: 0.2), value: fish.isStartled)
      .animation(.linear(duration: 0.016), value: fish.x)  // Smooth position updates
      .animation(.linear(duration: 0.016), value: fish.y)
      .onTapGesture { location in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
          fishTankManager.startleFish(fish, tapLocation: location)
        }
      }
    }
    .onAppear {
      // Animate glow opacity for shiny fish
      if fish.collectedFish.isShiny {
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
          glowOpacity = glowOpacity + 0.15
        }
      }
    }
  }
}
