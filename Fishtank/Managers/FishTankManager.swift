//
//  FishTankManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Fish Tank Manager
@MainActor
final class FishTankManager: ObservableObject {
  static let shared = FishTankManager(bounds: UIScreen.main.bounds)

  @Published var swimmingFish: [SwimmingFish] = []
  @Published var commitmentLootboxes: [CommitmentLootbox] = []
  private let bounds: CGRect
  private let startleDuration: TimeInterval = 3  // Duration of startled state
  private let startledSpeedMultiplier: CGFloat = 15.0  // How much faster fish swim when startled
  private let speedDecayRate: CGFloat = 0.985  // How quickly speed decays (multiply per frame)
  private let verticalChangeChance: CGFloat = 0.02  // Chance to change vertical direction per frame
  private let maxVerticalSpeed: CGFloat = 0.8  // Maximum vertical speed

  init(bounds: CGRect) {
    self.bounds = bounds
    loadState()
  }

  private func loadState() {
    // Load any saved state (lootboxes, etc.)
    if let savedLootboxes = UserDefaults.standard.array(forKey: "SavedLootboxes")
      as? [[String: Any]]
    {
      commitmentLootboxes = savedLootboxes.compactMap { dict in
        guard let typeRawValue = dict["type"] as? String,
          let type = LootboxType(rawValue: typeRawValue),
          let x = dict["x"] as? CGFloat,
          let y = dict["y"] as? CGFloat
        else { return nil }

        return CommitmentLootbox(type: type, x: x, y: y)
      }
    }
  }

  private func saveState() {
    // Save current state (lootboxes, etc.)
    let lootboxDicts = commitmentLootboxes.map { lootbox -> [String: Any] in
      return [
        "type": lootbox.type.rawValue,
        "x": lootbox.x,
        "y": lootbox.y,
      ]
    }
    UserDefaults.standard.set(lootboxDicts, forKey: "SavedLootboxes")
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

      // Update horizontal position
      swimmingFish[i].x -= swimmingFish[i].speed * swimmingFish[i].direction

      // Handle vertical movement
      if swimmingFish[i].isStartled {
        // Erratic vertical movement when startled
        let time = Date().timeIntervalSinceReferenceDate
        let verticalMovement = sin(time * 4) * 0.5  // Slower, gentler vertical movement
        swimmingFish[i].y += verticalMovement
      } else {
        // Natural vertical movement with gradual direction changes
        if CGFloat.random(in: 0...1) < verticalChangeChance {
          // Occasionally change vertical direction
          swimmingFish[i].verticalDirection = CGFloat.random(in: -1...1)
          swimmingFish[i].verticalSpeed = CGFloat.random(in: 0.05...0.15)
        }

        // Apply vertical movement with momentum
        let verticalMovement = swimmingFish[i].verticalSpeed * swimmingFish[i].verticalDirection
        swimmingFish[i].y += verticalMovement

        // Gradually slow down vertical speed for natural feel
        swimmingFish[i].verticalSpeed *= 0.995
        if swimmingFish[i].verticalSpeed < 0.01 {
          swimmingFish[i].verticalSpeed = 0.01
        }
      }

      // Keep fish within vertical bounds and handle bouncing
      let minY = bounds.height * 0.1
      let maxY = bounds.height * 0.9
      if swimmingFish[i].y < minY {
        swimmingFish[i].y = minY
        swimmingFish[i].verticalDirection = 1  // Bounce down
        swimmingFish[i].verticalSpeed *= 0.8  // Reduce speed on bounce
      } else if swimmingFish[i].y > maxY {
        swimmingFish[i].y = maxY
        swimmingFish[i].verticalDirection = -1  // Bounce up
        swimmingFish[i].verticalSpeed *= 0.8  // Reduce speed on bounce
      }

      // Bounce off walls
      if swimmingFish[i].x <= 0 || swimmingFish[i].x >= bounds.width * 0.9 {
        swimmingFish[i].direction *= -1
        // Slightly reduce speed on bounce for natural feel
        swimmingFish[i].speed *= 0.9
      }

      // Keep fish within horizontal bounds
      swimmingFish[i].x = max(0, min(bounds.width * 0.9, swimmingFish[i].x))
    }
  }

  func spawnLootbox(type: LootboxType) {
    let x = CGFloat.random(in: bounds.width * 0.2...bounds.width * 0.8)
    let y = CGFloat.random(in: bounds.height * 0.3...bounds.height * 0.7)

    let lootbox = CommitmentLootbox(type: type, x: x, y: y)
    commitmentLootboxes.append(lootbox)

    // Save state after adding lootbox
    saveState()
  }

  func removeLootbox(_ lootbox: CommitmentLootbox) {
    commitmentLootboxes.removeAll { $0.id == lootbox.id }

    // Save state after removing lootbox
    saveState()
  }

  func renameFish(id: UUID, newName: String) {
    if let index = swimmingFish.firstIndex(where: { $0.collectedFish.id == id }) {
      // We need to create a new instance since CollectedFish is inside SwimmingFish
      var updatedCollectedFish = swimmingFish[index].collectedFish
      updatedCollectedFish.name = newName

      // Create a new SwimmingFish with the updated CollectedFish
      var updatedSwimmingFish = swimmingFish[index]
      updatedSwimmingFish.collectedFish = updatedCollectedFish

      // Replace the fish in the array
      swimmingFish[index] = updatedSwimmingFish
      
      // Sync with Supabase
      Task {
        await SupabaseManager.shared.saveFishCollection(GameStatsManager.shared.collectedFish)
      }
    }
  }
}
