//
//  FishTankEnvironmentView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct FishTankEnvironmentView: View {
  @ObservedObject var fishTankManager: FishTankManager
  @ObservedObject var bubbleManager: BubbleManager
  let onLootboxTapped: (CommitmentLootbox, [CollectedFish]) -> Void
  
  var body: some View {
    ZStack {
      // Animated Bubbles
      ForEach(bubbleManager.bubbles) { bubble in
        BubbleView(bubble: bubble)
          .position(x: bubble.x, y: bubble.y)
          .animation(.linear(duration: 0.016), value: bubble.x)
          .animation(.linear(duration: 0.016), value: bubble.y)
      }

      // Swimming Fish
      ForEach(fishTankManager.swimmingFish) { fish in
        SwimmingFishView(fish: fish, fishTankManager: fishTankManager)
          .position(x: fish.x, y: fish.y)
      }

      // Commitment Lootboxes
      ForEach(fishTankManager.commitmentLootboxes) { lootbox in
        LootboxView(type: lootbox.type)
          .position(x: lootbox.x, y: lootbox.y)
          .onTapGesture {
            // Generate possible rewards for the wheel
            var possibleRewards: [CollectedFish] = []
            for _ in 0..<(lootbox.type.fishCount * 10) {  // Generate more options for variety
              let fish = FishDatabase.randomFish(from: lootbox.type)
              let collectedFish = CollectedFish(fish: fish)
              possibleRewards.append(collectedFish)
            }
            
            onLootboxTapped(lootbox, possibleRewards)
          }
      }
    }
  }
}

#Preview {
  FishTankEnvironmentView(
    fishTankManager: FishTankManager.shared,
    bubbleManager: BubbleManager.shared,
    onLootboxTapped: { _, _ in }
  )
} 