//
//  Managers.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import DeviceActivity
import FamilyControls
import ManagedSettings
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

// MARK: - Commitment Manager
class CommitmentManager: ObservableObject {
  @Published var currentCommitment: FocusCommitment?
  @Published var commitmentStartTime: Date?
  private let appRestrictionManager = AppRestrictionManager()

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

  var isAppRestrictionEnabled: Bool {
    appRestrictionManager.isAuthorized
  }

  func startCommitment(_ commitment: FocusCommitment) {
    currentCommitment = commitment
    commitmentStartTime = Date()

    // Start app restriction if authorized
    if appRestrictionManager.isAuthorized {
      appRestrictionManager.startAppRestriction()
    }
  }

  func cancelCommitment() -> FocusCommitment? {
    let cancelledCommitment = currentCommitment
    currentCommitment = nil
    commitmentStartTime = nil

    // Stop app restriction
    appRestrictionManager.stopAppRestriction()

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

      // Stop app restriction when commitment is completed
      appRestrictionManager.stopAppRestriction()

      return completedCommitment
    }

    return nil
  }

  func requestAppRestrictionAuthorization() {
    appRestrictionManager.requestAuthorization()
  }

  func debugFinishCommitment() -> FocusCommitment? {
    guard let commitment = currentCommitment else { return nil }

    // Set start time to a point in the past that would make the commitment complete
    commitmentStartTime = Date().addingTimeInterval(-commitment.duration - 1)

    // Check progress immediately to trigger completion
    return checkProgress()
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

  func addFish(_ fish: CollectedFish, fishTankManager: FishTankManager? = nil) {
    // Check if we already have 10 visible fish - if so, hide the new fish
    let currentVisibleCount = getVisibleFish().count
    var newFish = fish
    if currentVisibleCount >= AppConfig.maxSwimmingFish {
      newFish.isVisible = false
    }

    collectedFish.append(newFish)
    fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    saveToStorage()
    // Update swimming fish display if manager provided
    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }
  }

  func addFishes(_ fishes: [CollectedFish], fishTankManager: FishTankManager? = nil) {
    let currentVisibleCount = getVisibleFish().count
    var visibleSlotsLeft = max(0, AppConfig.maxSwimmingFish - currentVisibleCount)

    for fish in fishes {
      var newFish = fish
      if visibleSlotsLeft > 0 {
        newFish.isVisible = true
        visibleSlotsLeft -= 1
      } else {
        newFish.isVisible = false
      }

      collectedFish.append(newFish)
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

  func toggleFishVisibility(_ fish: CollectedFish, fishTankManager: FishTankManager) -> Bool {
    if let index = collectedFish.firstIndex(of: fish) {
      // If fish is currently hidden and user wants to show it, check the limit
      if !collectedFish[index].isVisible {
        let currentVisibleCount = getVisibleFish().count
        if currentVisibleCount >= AppConfig.maxSwimmingFish {
          // Cannot show more fish - limit reached
          return false
        }
      }

      collectedFish[index].isVisible.toggle()
      saveToStorage()
      // Update swimming fish display
      fishTankManager.updateSwimmingFish(with: getVisibleFish())
      return true
    }
    return false
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

// MARK: - App Restriction Manager
class AppRestrictionManager: ObservableObject {
  @Published var isRestrictionActive = false
  private let store = ManagedSettingsStore()
  private let center = AuthorizationCenter.shared

  init() {
    // Request authorization when the manager is initialized
    requestAuthorization()
  }

  func requestAuthorization() {
    Task {
      do {
        try await center.requestAuthorization(for: .individual)
        print("Screen Time authorization granted")
      } catch {
        print("Screen Time authorization failed: \(error)")
      }
    }
  }

  func startAppRestriction() {
    guard center.authorizationStatus == .approved else {
      print("Screen Time authorization not approved")
      return
    }

    // Shield all app categories. The system prevents the app that sets the restriction from being blocked.
    store.shield.applicationCategories = .all()

    isRestrictionActive = true
    print("App restriction started")
  }

  func stopAppRestriction() {
    // Remove all restrictions
    store.shield.applicationCategories = nil
    store.shield.applications = nil

    isRestrictionActive = false
    print("App restriction stopped")
  }

  var isAuthorized: Bool {
    center.authorizationStatus == .approved
  }
}
