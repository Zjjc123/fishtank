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

  init(bounds: CGRect) {
    self.bounds = bounds
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
      swimmingFish[i].x += swimmingFish[i].speed * swimmingFish[i].direction

      if swimmingFish[i].x <= 0 || swimmingFish[i].x >= bounds.width {
        swimmingFish[i].direction *= -1
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