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
    let winningRarity = FishRarity.randomRarity(boost: lootboxType.rarityBoost)
    return CollectedFish(rarity: winningRarity)
  }
}

// MARK: - Reward Item View
struct RewardItemView: View {
  let fish: CollectedFish
  let isSelected: Bool

  var body: some View {
    VStack(spacing: 5) {
      Text(fish.emoji)
        .font(.title)
        .frame(width: 50, height: 50)

      Text(fish.rarity.rawValue)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(fish.rarity.color)
        .lineLimit(1)
    }
    .padding(8)
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
