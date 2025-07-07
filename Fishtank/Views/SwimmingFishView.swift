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
  @State private var glowOpacity: Double = 0.3

  var body: some View {
    ZStack {
      // Glow effect for shiny fish
      if fish.collectedFish.isShiny {
        // Outer glow layer (largest, most diffused)
        Image(fish.imageName)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size, height: fish.size)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .blur(radius: 15)
          .foregroundColor(Color.yellow)
          .opacity(glowOpacity * 0.6)
          .animation(
            Animation.easeInOut(duration: 1.5)
              .repeatForever(autoreverses: true),
            value: glowOpacity
          )

        // Middle glow layer
        Image(fish.imageName)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size, height: fish.size)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .blur(radius: 8)
          .foregroundColor(Color.yellow)
          .opacity(glowOpacity * 1.0)
          .animation(
            Animation.easeInOut(duration: 1.5)
              .repeatForever(autoreverses: true),
            value: glowOpacity
          )

        // Inner bright glow layer
        Image(fish.imageName)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size, height: fish.size)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .blur(radius: 3)
          .foregroundColor(Color.yellow)
          .opacity(glowOpacity * 1.4)
          .animation(
            Animation.easeInOut(duration: 1.5)
              .repeatForever(autoreverses: true),
            value: glowOpacity
          )
          .onAppear {
            glowOpacity = 1.0
          }

        // Bright yellow highlight layer
        Image(fish.imageName)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size, height: fish.size)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .blur(radius: 1)
          .foregroundColor(Color.yellow)
          .opacity(glowOpacity * 1.8)
          .animation(
            Animation.easeInOut(duration: 1.5)
              .repeatForever(autoreverses: true),
            value: glowOpacity
          )

        // Extra bright yellow overlay
        Image(fish.imageName)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: fish.size, height: fish.size)
          .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
          .foregroundColor(Color.yellow)
          .opacity(glowOpacity * 0.3)
          .animation(
            Animation.easeInOut(duration: 1.5)
              .repeatForever(autoreverses: true),
            value: glowOpacity
          )
      }

      // Main fish image
      Image(fish.imageName)
        .resizable()
        .interpolation(.none)
        .aspectRatio(contentMode: .fit)
        .frame(width: fish.size, height: fish.size)
        .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
        .shadow(color: .black.opacity(0.3), radius: 2)
        .opacity(fish.isStartled ? 0.7 : 1.0)
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
  }
}
