//
//  SpinnerView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Spinner View
struct SpinnerView: View {
  let lootboxType: LootboxType
  let possibleRewards: [CollectedFish]
  let predeterminedWinner: CollectedFish
  let onSpinComplete: (CollectedFish) -> Void

  @State private var wheelOffset: CGFloat = 0
  @State private var isSpinning = false
  @State private var randomizedFish: [CollectedFish] = []

  private let itemWidth: CGFloat = 80
  private let itemSpacing: CGFloat = 20
  private let totalItems = 30
  private let winningIndex = 20  // The index where we want the winner to appear

  var body: some View {
    ZStack {
      // Wheel background
      RoundedRectangle(cornerRadius: 15)
        .fill(.ultraThinMaterial)
        .frame(height: 100)
        .overlay(
          RoundedRectangle(cornerRadius: 15)
            .stroke(lootboxType.color.opacity(0.5), lineWidth: 2)
        )

      // Selection indicator (center line)
      Rectangle()
        .fill(Color.yellow)
        .frame(width: 3, height: 100)
        .shadow(color: .yellow, radius: 5)
        .zIndex(1)

      // Scrolling items
      HStack(spacing: itemSpacing) {
        ForEach(0..<totalItems, id: \.self) { index in
          let fish = getFishForPosition(index)
          RewardItemView(fish: fish, isSelected: false)
            .frame(width: itemWidth)
        }
      }
      .offset(x: wheelOffset)
      .clipped()
    }
    .frame(maxWidth: 350)
    .padding(.horizontal)
    .onAppear {
      generateRandomizedFish()
      startSpinning()
    }
  }

  private func generateRandomizedFish() {
    // Generate randomized fish for all positions except the winning index
    randomizedFish = []
    for _ in 0..<(totalItems - 1) {
      let fish = FishDatabase.randomFish(from: lootboxType, isSpinner: true)
      randomizedFish.append(CollectedFish(fish: fish))
    }
  }

  private func getFishForPosition(_ index: Int) -> CollectedFish {
    // Place the predetermined winner at the winning index
    if index == winningIndex {
      return predeterminedWinner
    }

    // Guard against accessing an empty array before onAppear populates it.
    guard !randomizedFish.isEmpty else {
      // Return a temporary placeholder. It will be updated once onAppear runs.
      return predeterminedWinner
    }

    // Use the pre-generated randomized fish for other positions
    let fishIndex = index < winningIndex ? index : index - 1
    return randomizedFish[fishIndex]
  }

  private func startSpinning() {
    // Position the wheel so the predetermined winner ends up centered under the selection indicator
    let totalItemWidth = itemWidth + itemSpacing

    // Calculate offset to center the winning item under the selection indicator
    // The HStack naturally centers itself, so the center would be at index (totalItems-1)/2 = 14.5
    // We want index 20 to be at center instead, so we shift right by (14.5 - 20) = -5.5 positions
    let naturalCenter = CGFloat(totalItems - 1) / 2.0
    let offsetPositions = naturalCenter - CGFloat(winningIndex)
    let baseOffset = offsetPositions * totalItemWidth

    // Add slight random noise to make the landing feel more natural
    let noiseRange = totalItemWidth * 0.3  // 30% of item width for noise
    let randomNoise = CGFloat.random(in: -noiseRange...noiseRange)
    let finalOffset = baseOffset + randomNoise

    // Start with wheel positioned further to create more dramatic spin effect
    let initialOffset: CGFloat = finalOffset + (totalItemWidth * 15)
    wheelOffset = initialOffset

    isSpinning = true

    // Animate the wheel spinning with dramatic effect
    withAnimation(.easeOut(duration: 5.0)) {
      wheelOffset = finalOffset
    }

    // Notify parent when spin completes with the predetermined winner
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
      isSpinning = false
      onSpinComplete(predeterminedWinner)
    }
  }
}
