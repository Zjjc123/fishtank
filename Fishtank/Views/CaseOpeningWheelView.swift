//
//  CaseOpeningWheelView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

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
    let fish = FishDatabase.randomFish(from: lootboxType)
    return CollectedFish(fish: fish)
  }
} 