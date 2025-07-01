//
//  FishTankManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Fish Tank Manager
class FishTankManager: ObservableObject {
  @Published var swimmingFish: [SwimmingFish] = []
  @Published var commitmentLootboxes: [CommitmentLootbox] = []

  private let bounds: CGRect
  private let startleDuration: TimeInterval = 3  // Duration of startled state
  private let startledSpeedMultiplier: CGFloat = 15.0  // How much faster fish swim when startled
  private let speedDecayRate: CGFloat = 0.985  // How quickly speed decays (multiply per frame)

  init(bounds: CGRect) {
    self.bounds = bounds
  }

  func startleFish(_ targetFish: SwimmingFish, tapLocation: CGPoint) {
    guard let index = swimmingFish.firstIndex(where: { $0.id == targetFish.id }) else { return }

    // Start the startle effect
    swimmingFish[index].isStartled = true
    swimmingFish[index].startledTime = Date()

    // Set maximum speed immediately
    swimmingFish[index].speed = swimmingFish[index].originalSpeed * startledSpeedMultiplier

    // Set a random direction when startled
    let randomAngle = CGFloat.random(in: -CGFloat.pi / 4...CGFloat.pi / 4)  // Random angle ±45°
    swimmingFish[index].direction = randomAngle > 0 ? 1 : -1
  }

  func addSwimmingFish(from collectedFish: CollectedFish) {
    if swimmingFish.count < AppConfig.maxSwimmingFish {
      let swimmingFish = SwimmingFish(collectedFish: collectedFish, in: bounds)
      self.swimmingFish.append(swimmingFish)
    }
  }

  func updateSwimmingFish(with visibleFish: [CollectedFish]) {
    // Create a set of currently swimming fish IDs for quick lookup
    let currentSwimmingIDs = Set(swimmingFish.map { $0.collectedFish.id })

    // Create a set of visible fish IDs
    let visibleFishIDs = Set(visibleFish.map { $0.id })

    // Remove fish that are no longer visible
    swimmingFish.removeAll { fish in
      !visibleFishIDs.contains(fish.collectedFish.id)
    }

    // Add new visible fish that aren't already swimming (up to max limit)
    let availableSlots = AppConfig.maxSwimmingFish - swimmingFish.count
    let newFishToAdd = visibleFish.filter { !currentSwimmingIDs.contains($0.id) }

    for fish in Array(newFishToAdd.prefix(availableSlots)) {
      let swimmingFish = SwimmingFish(collectedFish: fish, in: bounds)
      self.swimmingFish.append(swimmingFish)
    }
  }

  func animateFish() {
    for i in swimmingFish.indices {
      // Check if we need to end startled state
      if swimmingFish[i].isStartled,
        let startledTime = swimmingFish[i].startledTime,
        Date().timeIntervalSince(startledTime) >= startleDuration
      {
        // End startled state but keep current speed (will decay naturally)
        swimmingFish[i].isStartled = false
        swimmingFish[i].startledTime = nil
      }

      // Apply speed decay if speed is above original
      if swimmingFish[i].speed > swimmingFish[i].originalSpeed {
        swimmingFish[i].speed *= speedDecayRate

        // Prevent speed from going below original
        if swimmingFish[i].speed < swimmingFish[i].originalSpeed {
          swimmingFish[i].speed = swimmingFish[i].originalSpeed
        }
      }

      // Update position
      swimmingFish[i].x -= swimmingFish[i].speed * swimmingFish[i].direction

      // Handle vertical movement for startled fish
      if swimmingFish[i].isStartled {
        let time = Date().timeIntervalSinceReferenceDate
        let verticalMovement = sin(time * 4) * 0.5  // Slower, gentler vertical movement
        swimmingFish[i].y += verticalMovement

        // Keep within bounds with smooth clamping
        let targetY = max(bounds.height * 0.2, min(bounds.height * 0.8, swimmingFish[i].y))
        swimmingFish[i].y = swimmingFish[i].y * 0.9 + targetY * 0.1  // Smooth transition to bounds
      }

      // Bounce off walls
      if swimmingFish[i].x <= 0 || swimmingFish[i].x >= bounds.width {
        swimmingFish[i].direction *= -1
        // Slightly reduce speed on bounce for natural feel
        swimmingFish[i].speed *= 0.9
      }

      swimmingFish[i].x = max(0, min(bounds.width, swimmingFish[i].x))
    }
  }

  func spawnLootbox(type: LootboxType) {
    let lootbox = CommitmentLootbox(
      type: type,
      x: CGFloat.random(in: 50...bounds.width - 50),
      y: CGFloat.random(in: bounds.height * 0.3...bounds.height * 0.7)
    )
    commitmentLootboxes.append(lootbox)
  }

  func removeLootbox(_ lootbox: CommitmentLootbox) {
    if let index = commitmentLootboxes.firstIndex(where: { $0.id == lootbox.id }) {
      commitmentLootboxes.remove(at: index)
    }
  }
}
