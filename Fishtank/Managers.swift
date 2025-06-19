//
//  Managers.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Fish Tank Manager
class FishTankManager: ObservableObject {
  @Published var swimmingFish: [SwimmingFish] = []
  @Published var giftBoxes: [GiftBox] = []
  @Published var commitmentLootboxes: [CommitmentLootbox] = []

  private var lastGiftBoxTime: TimeInterval = 0
  private let bounds: CGRect

  init(bounds: CGRect) {
    self.bounds = bounds
  }

  func updateBounds(_ newBounds: CGRect) {
    // Update bounds if needed for screen rotation, etc.
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

  func spawnGiftBoxIfNeeded(timeSpent: TimeInterval) -> Bool {
    let minutes = Int(timeSpent) / 60
    if timeSpent >= lastGiftBoxTime + AppConfig.giftBoxInterval && minutes > 0 {
      spawnGiftBox()
      lastGiftBoxTime = timeSpent
      return true
    }
    return false
  }

  private func spawnGiftBox() {
    let giftBox = GiftBox(
      x: CGFloat.random(in: 50...bounds.width - 50),
      y: CGFloat.random(in: bounds.height * 0.3...bounds.height * 0.7)
    )
    giftBoxes.append(giftBox)
  }

  func openGiftBox(_ giftBox: GiftBox) -> CollectedFish {
    if let index = giftBoxes.firstIndex(where: { $0.id == giftBox.id }) {
      giftBoxes.remove(at: index)
    }

    let rarity = FishRarity.randomRarity()
    let newFish = CollectedFish(rarity: rarity)

    return newFish
  }

  func spawnCommitmentLootbox(type: LootboxType) {
    let lootbox = CommitmentLootbox(
      type: type,
      x: CGFloat.random(in: 50...bounds.width - 50),
      y: CGFloat.random(in: bounds.height * 0.3...bounds.height * 0.7)
    )
    commitmentLootboxes.append(lootbox)
  }

  func openLootbox(_ lootbox: CommitmentLootbox) -> [CollectedFish] {
    if let index = commitmentLootboxes.firstIndex(where: { $0.id == lootbox.id }) {
      commitmentLootboxes.remove(at: index)
    }

    var newFishes: [CollectedFish] = []
    for _ in 0..<lootbox.type.fishCount {
      let rarity = FishRarity.randomRarity(boost: lootbox.type.rarityBoost)
      let newFish = CollectedFish(rarity: rarity)
      newFishes.append(newFish)
    }

    return newFishes
  }

}

// MARK: - Commitment Manager
class CommitmentManager: ObservableObject {
  @Published var currentCommitment: FocusCommitment?
  @Published var commitmentStartTime: Date?

  var progress: Double {
    guard let commitment = currentCommitment,
      let startTime = commitmentStartTime
    else { return 0 }

    let elapsed = Date().timeIntervalSince(startTime)
    return min(elapsed / commitment.duration, 1.0)
  }

  var timeRemaining: TimeInterval {
    guard let commitment = currentCommitment,
      let startTime = commitmentStartTime
    else { return 0 }

    let elapsed = Date().timeIntervalSince(startTime)
    return max(commitment.duration - elapsed, 0)
  }

  var isActive: Bool {
    currentCommitment != nil
  }

  func startCommitment(_ commitment: FocusCommitment) {
    currentCommitment = commitment
    commitmentStartTime = Date()
  }

  func cancelCommitment() -> FocusCommitment? {
    let cancelledCommitment = currentCommitment
    currentCommitment = nil
    commitmentStartTime = nil
    return cancelledCommitment
  }

  func checkProgress() -> FocusCommitment? {
    guard let commitment = currentCommitment,
      let startTime = commitmentStartTime
    else { return nil }

    let elapsed = Date().timeIntervalSince(startTime)

    if elapsed >= commitment.duration {
      let completedCommitment = commitment
      currentCommitment = nil
      commitmentStartTime = nil
      return completedCommitment
    }

    return nil
  }
}

// MARK: - Persistent Storage Manager
class PersistentStorageManager {
  private static let collectedFishKey = "CollectedFish"
  private static let fishCollectionKey = "FishCollection"

  static func saveFish(_ fish: [CollectedFish]) {
    do {
      let data = try JSONEncoder().encode(fish)
      UserDefaults.standard.set(data, forKey: collectedFishKey)
    } catch {
      print("Failed to save fish collection: \(error)")
    }
  }

  static func loadFish() -> [CollectedFish] {
    guard let data = UserDefaults.standard.data(forKey: collectedFishKey) else {
      return []
    }

    do {
      return try JSONDecoder().decode([CollectedFish].self, from: data)
    } catch {
      print("Failed to load fish collection: \(error)")
      return []
    }
  }

  static func saveFishCollection(_ collection: [FishRarity: Int]) {
    do {
      let data = try JSONEncoder().encode(collection)
      UserDefaults.standard.set(data, forKey: fishCollectionKey)
    } catch {
      print("Failed to save fish collection stats: \(error)")
    }
  }

  static func loadFishCollection() -> [FishRarity: Int] {
    guard let data = UserDefaults.standard.data(forKey: fishCollectionKey) else {
      return [:]
    }

    do {
      return try JSONDecoder().decode([FishRarity: Int].self, from: data)
    } catch {
      print("Failed to load fish collection stats: \(error)")
      return [:]
    }
  }

  static func clearAllData() {
    UserDefaults.standard.removeObject(forKey: collectedFishKey)
    UserDefaults.standard.removeObject(forKey: fishCollectionKey)
  }
}

// MARK: - Game Stats Manager
class GameStatsManager: ObservableObject {
  @Published var collectedFish: [CollectedFish] = []
  @Published var fishCollection: [FishRarity: Int] = [:]

  var fishCount: Int {
    collectedFish.count
  }

  init() {
    loadFromStorage()

    // If no fish were loaded (first launch), add starter fish
    if collectedFish.isEmpty {
      addStarterFish()
    }
  }

  private func loadFromStorage() {
    collectedFish = PersistentStorageManager.loadFish()
    fishCollection = PersistentStorageManager.loadFishCollection()

    // If collection stats are empty but we have fish, recalculate
    if fishCollection.isEmpty && !collectedFish.isEmpty {
      recalculateFishCollection()
    } else if fishCollection.isEmpty {
      initializeFishCollection()
    }
  }

  private func saveToStorage() {
    PersistentStorageManager.saveFish(collectedFish)
    PersistentStorageManager.saveFishCollection(fishCollection)
  }

  private func initializeFishCollection() {
    for rarity in FishRarity.allCases {
      fishCollection[rarity] = 0
    }
  }

  private func recalculateFishCollection() {
    initializeFishCollection()
    for fish in collectedFish {
      fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    }
  }

  private func addStarterFish() {
    // Add 3 common starter fish
    for _ in 0..<AppConfig.initialFishCount {
      let starterFish = CollectedFish(rarity: .common)
      addFish(starterFish)
    }
  }

  func addFish(_ fish: CollectedFish, fishTankManager: FishTankManager? = nil) {
    collectedFish.append(fish)
    fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    saveToStorage()
    // Update swimming fish display if manager provided
    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }
  }

  func addFishes(_ fishes: [CollectedFish], fishTankManager: FishTankManager? = nil) {
    for fish in fishes {
      collectedFish.append(fish)
      fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    }
    saveToStorage()
    // Update swimming fish display if manager provided
    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }
  }

  func getFishByRarity(_ rarity: FishRarity) -> [CollectedFish] {
    return collectedFish.filter { $0.rarity == rarity }
  }

  func getRecentFish(limit: Int = 5) -> [CollectedFish] {
    return Array(collectedFish.suffix(limit))
  }

  func removeFish(_ fish: CollectedFish) {
    if let index = collectedFish.firstIndex(of: fish) {
      collectedFish.remove(at: index)
      fishCollection[fish.rarity] = max(0, (fishCollection[fish.rarity] ?? 0) - 1)
      saveToStorage()
    }
  }

  func clearAllFish() {
    collectedFish.removeAll()
    initializeFishCollection()
    saveToStorage()
  }

  func toggleFishVisibility(_ fish: CollectedFish, fishTankManager: FishTankManager) {
    if let index = collectedFish.firstIndex(of: fish) {
      collectedFish[index].isVisible.toggle()
      saveToStorage()
      // Update swimming fish display
      fishTankManager.updateSwimmingFish(with: getVisibleFish())
    }
  }

  func getVisibleFish() -> [CollectedFish] {
    return collectedFish.filter { $0.isVisible }
  }

  func getHiddenFish() -> [CollectedFish] {
    return collectedFish.filter { !$0.isVisible }
  }

  func exportFishCollection() -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    do {
      let data = try encoder.encode(collectedFish)
      return String(data: data, encoding: .utf8) ?? "Export failed"
    } catch {
      return "Export error: \(error)"
    }
  }
}
