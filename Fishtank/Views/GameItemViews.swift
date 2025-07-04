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
  @ObservedObject var fishTankManager: FishTankManager

  var body: some View {
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
      .animation(.linear(duration: 0.016), value: fish.x) // Smooth position updates
      .animation(.linear(duration: 0.016), value: fish.y)
      .onTapGesture { location in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
          fishTankManager.startleFish(fish, tapLocation: location)
        }
      }
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

// MARK: - Case Opening Wheel View
struct CaseOpeningWheelView: View {
  let lootboxType: LootboxType
  let possibleRewards: [CollectedFish]
  let selectedReward: CollectedFish
  @Binding var isPresented: Bool
  let onComplete: ([CollectedFish]) -> Void

  @State private var showRewards = false
  @State private var predeterminedWinner: CollectedFish?

  var body: some View {
    ZStack {
      // Background overlay
      Color.black.opacity(0.8)
        .ignoresSafeArea()

      VStack(spacing: 20) {
        // Header
        VStack(spacing: 8) {
          Text("Opening \(lootboxType.emoji)")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.white)

          Text("\(lootboxType.rawValue) Lootbox")
            .font(.headline)
            .foregroundColor(lootboxType.color)
        }

        // Spinner
        if let winner = predeterminedWinner {
          SpinnerView(
            lootboxType: lootboxType,
            possibleRewards: possibleRewards,
            predeterminedWinner: winner,
            onSpinComplete: { winningFish in
              withAnimation(.spring()) {
                showRewards = true
              }
            }
          )
        }

        // Reward display
        if showRewards, let winner = predeterminedWinner {
          VStack(spacing: 6) {
            HStack(spacing: 4) {
              // Show the predetermined winning fish
              ForEach(0..<lootboxType.fishCount, id: \.self) { _ in
                RewardItemView(fish: winner, isSelected: true)
                  .scaleEffect(1.0)
              }
            }
            .padding(.bottom, 10)

            Button("Collect Rewards") {
              let rewards = Array(repeating: winner, count: lootboxType.fishCount)
              onComplete(rewards)
              isPresented = false
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
              RoundedRectangle(cornerRadius: 10)
                .fill(Color.green)
            )
          }
        }
      }
      .padding(.top, 20)
      .padding(.bottom, 40)
    }
    .onAppear {
      // Predetermine the winner based on lootbox rarity probabilities
      predeterminedWinner = determineWinner()
    }
  }

  private func determineWinner() -> CollectedFish {
    // Generate a winning fish based on the lootbox's rarity boost
    let winningRarity = FishRarity.randomRarity(from: lootboxType)
    return CollectedFish(rarity: winningRarity)
  }
}

// MARK: - Reward Item View
struct RewardItemView: View {
  let fish: CollectedFish
  let isSelected: Bool

  var body: some View {
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

// MARK: - Bubble View
struct BubbleView: View {
  let bubble: Bubble

  var body: some View {
    ZStack {
      // Main bubble circle
      Circle()
        .fill(Color.white.opacity(bubble.opacity * 0.3))
        .frame(width: bubble.size, height: bubble.size)
        .overlay(
          Circle()
            .stroke(Color.white.opacity(bubble.opacity * 0.6), lineWidth: 1)
        )

      // Highlight reflection
      Circle()
        .fill(Color.white.opacity(bubble.opacity * 0.4))
        .frame(width: bubble.size * 0.3, height: bubble.size * 0.3)
        .offset(x: -bubble.size * 0.2, y: -bubble.size * 0.2)

      // Secondary reflection
      Circle()
        .fill(Color.white.opacity(bubble.opacity * 0.2))
        .frame(width: bubble.size * 0.15, height: bubble.size * 0.15)
        .offset(x: bubble.size * 0.15, y: -bubble.size * 0.25)
    }
    .blur(radius: 0.5)
  }
}
