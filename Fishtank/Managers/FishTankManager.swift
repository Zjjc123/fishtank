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
  private var bounds: CGRect
  private let startleDuration: TimeInterval = 3  // Duration of startled state
  private let startledSpeedMultiplier: CGFloat = 15.0  // How much faster fish swim when startled
  private let speedDecayRate: CGFloat = 0.985  // How quickly speed decays (multiply per frame)
  private let verticalChangeChance: CGFloat = 0.02  // Chance to change vertical direction per frame
  private let maxVerticalSpeed: CGFloat = 0.8  // Maximum vertical speed
  private let supabaseManager = SupabaseManager.shared

  init(bounds: CGRect) {
    // Always use landscape bounds (width > height)
    let screenBounds = bounds
    self.bounds = screenBounds.width > screenBounds.height ? screenBounds : 
                  CGRect(x: 0, y: 0, width: screenBounds.height, height: screenBounds.width)
    loadState()
  }

  // Update bounds when orientation changes
  func updateBounds(newBounds: CGRect) {
    // Always use landscape bounds (width > height)
    let landscapeBounds = newBounds.width > newBounds.height ? newBounds : 
                          CGRect(x: 0, y: 0, width: newBounds.height, height: newBounds.width)
    
    let widthRatio = landscapeBounds.width / bounds.width
    let heightRatio = landscapeBounds.height / bounds.height

    // Update fish positions based on the new bounds
    for i in swimmingFish.indices {
      // Scale positions proportionally to new bounds
      swimmingFish[i].x *= widthRatio
      swimmingFish[i].y *= heightRatio

      // Ensure fish stay within bounds
      swimmingFish[i].x = max(0, min(landscapeBounds.width * 0.9, swimmingFish[i].x))
      swimmingFish[i].y = max(
        landscapeBounds.height * 0.1, min(landscapeBounds.height * 0.9, swimmingFish[i].y))
    }

    // Update lootbox positions
    for i in commitmentLootboxes.indices {
      commitmentLootboxes[i].x *= widthRatio
      commitmentLootboxes[i].y *= heightRatio

      // Ensure lootboxes stay within bounds
      commitmentLootboxes[i].x = max(0, min(landscapeBounds.width * 0.8, commitmentLootboxes[i].x))
      commitmentLootboxes[i].y = max(
        landscapeBounds.height * 0.3, min(landscapeBounds.height * 0.7, commitmentLootboxes[i].y))
    }

    // Update the bounds
    self.bounds = landscapeBounds

    // Save the updated state
    saveState()
  }

  private func loadState() {
    // Load lootboxes from local storage as cache
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

    // If user is authenticated, we could potentially load lootboxes from Supabase as well
    // This would require additional database tables and methods in SupabaseManager
  }

  private func saveState() {
    // Save current state to local storage as cache
    let lootboxDicts = commitmentLootboxes.map { lootbox -> [String: Any] in
      return [
        "type": lootbox.type.rawValue,
        "x": lootbox.x,
        "y": lootbox.y,
      ]
    }
    UserDefaults.standard.set(lootboxDicts, forKey: "SavedLootboxes")

    // If user is authenticated, we could potentially save lootboxes to Supabase as well
    // This would require additional database tables and methods in SupabaseManager
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
    // Ensure we're using landscape bounds
    let landscapeBounds = bounds.width > bounds.height ? bounds : 
                          CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
    
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
      let minY = landscapeBounds.height * 0.1
      let maxY = landscapeBounds.height * 0.9
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
      if swimmingFish[i].x <= 0 || swimmingFish[i].x >= landscapeBounds.width * 0.9 {
        swimmingFish[i].direction *= -1
        // Slightly reduce speed on bounce for natural feel
        swimmingFish[i].speed *= 0.9
      }

      // Keep fish within horizontal bounds
      swimmingFish[i].x = max(0, min(landscapeBounds.width * 0.9, swimmingFish[i].x))
    }
  }

  func spawnLootbox(type: LootboxType) {
    // Ensure we're using landscape bounds
    let landscapeBounds = bounds.width > bounds.height ? bounds : 
                          CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
    
    let x = CGFloat.random(in: landscapeBounds.width * 0.2...landscapeBounds.width * 0.8)
    let y = CGFloat.random(in: landscapeBounds.height * 0.3...landscapeBounds.height * 0.7)

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

      // Update the swimming fish with the new name
      swimmingFish[index].collectedFish = updatedCollectedFish
    }
  }
}
