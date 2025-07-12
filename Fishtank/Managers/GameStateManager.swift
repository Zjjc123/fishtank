//
//  GameStateManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Combine
import Supabase
import SwiftUI

// MARK: - Game Stats Manager
@MainActor
final class GameStateManager: ObservableObject {
  static let shared = GameStateManager()

  @Published private(set) var collectedFish: [CollectedFish] = []
  @Published private(set) var fishCollection: [FishRarity: Int] = [:]
  @Published private(set) var isSyncing: Bool = false

  private let localStorageKey = "dev.jasonzhang.fishtank.collectedFish"
  private let supabaseManager = SupabaseManager.shared
  private var cancellables = Set<AnyCancellable>()

  private init() {
    // Initialize with empty state first
    initializeFishCollection()

    // Load fish from local storage first
    loadFromLocalStorage()

    // Listen for authentication state changes
    supabaseManager.$isAuthenticated
      .sink { [weak self] isAuthenticated in
        if isAuthenticated {
          print("🔐 GameStateManager: User authenticated, merging cloud and local data")
          Task {
            await self?.mergeCloudAndLocalData()
          }
        } else {
          print("🔐 GameStateManager: User unauthenticated, using local data only")
          self?.loadFromLocalStorage()
        }
      }
      .store(in: &cancellables)
  }

  var fishCount: Int {
    collectedFish.count
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

  // MARK: - Local Storage Methods

  private func saveToLocalStorage() {
    do {
      let encoder = JSONEncoder()
      let data = try encoder.encode(collectedFish)
      UserDefaults.standard.set(data, forKey: localStorageKey)
      print("💾 GameStateManager: Saved \(collectedFish.count) fish to local storage")
    } catch {
      print("❌ GameStateManager: Error saving to local storage: \(error)")
    }
  }

  private func loadFromLocalStorage() {
    guard let data = UserDefaults.standard.data(forKey: localStorageKey) else {
      print("💾 GameStateManager: No local fish data found")
      return
    }

    do {
      let decoder = JSONDecoder()
      let localFish = try decoder.decode([CollectedFish].self, from: data)
      collectedFish = localFish
      recalculateFishCollection()
      print("💾 GameStateManager: Loaded \(collectedFish.count) fish from local storage")
    } catch {
      print("❌ GameStateManager: Error loading from local storage: \(error)")
    }
  }

  // MARK: - Data Merging

  private func mergeCloudAndLocalData() async {
    print("🔄 GameStateManager: Starting cloud and local data merge")

    // Load local fish first
    var localFish: [CollectedFish] = []
    if let data = UserDefaults.standard.data(forKey: localStorageKey) {
      do {
        let decoder = JSONDecoder()
        localFish = try decoder.decode([CollectedFish].self, from: data)
        print("🔄 GameStateManager: Found \(localFish.count) fish in local storage for merging")
      } catch {
        print("❌ GameStateManager: Error loading local fish for merging: \(error)")
        localFish = []
      }
    }

    // Load cloud fish
    let cloudFish = await supabaseManager.loadFishCollection()
    print("🔄 GameStateManager: Found \(cloudFish.count) fish in cloud for merging")

    // Create dictionaries for easier merging
    var fishById = [String: CollectedFish]()

    // Add cloud fish first
    for fish in cloudFish {
      fishById[fish.id.uuidString] = fish
    }

    // Add local fish, potentially overriding cloud fish
    for fish in localFish {
      if let existingFish = fishById[fish.id.uuidString] {
        // If fish exists in both, use the most recently updated one
        if fish.updatedAt > existingFish.updatedAt {
          fishById[fish.id.uuidString] = fish
        }
      } else {
        // If fish only exists locally, add it
        fishById[fish.id.uuidString] = fish
      }
    }

    // Convert back to array
    let mergedFish = Array(fishById.values)
    print("🔄 GameStateManager: Merged collection has \(mergedFish.count) fish")

    // Update our collection
    collectedFish = mergedFish
    recalculateFishCollection()

    // Save the merged collection locally
    saveToLocalStorage()

    // Sync the merged collection to Supabase
    if supabaseManager.isAuthenticated {
      do {
        try await syncEntireCollectionToSupabase()
        print("✅ GameStateManager: Successfully synced merged collection to Supabase")
      } catch {
        print("❌ GameStateManager: Failed to sync merged collection: \(error)")
      }
    }
  }

  // MARK: - Fish Collection Methods

  @discardableResult
  func addFish(_ fish: CollectedFish, fishTankManager: FishTankManager? = nil) async throws {
    let currentVisibleCount = getVisibleFish().count
    var newFish = fish
    if currentVisibleCount >= AppConfig.maxSwimmingFish {
      newFish.isVisible = false
    }
    newFish.updatedAt = Date()
    collectedFish.append(newFish)
    fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1

    // Update local storage
    saveToLocalStorage()

    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }

    // Sync to Supabase if authenticated
    if supabaseManager.isAuthenticated {
      do {
        try await syncEntireCollectionToSupabase()
      } catch {
        print("❌ Error syncing to Supabase after adding fish: \(error)")
        throw error
      }
    }
  }

  @discardableResult
  func addFishes(_ fishes: [CollectedFish], fishTankManager: FishTankManager? = nil) async throws {
    let currentVisibleCount = getVisibleFish().count
    var visibleSlotsLeft = max(0, AppConfig.maxSwimmingFish - currentVisibleCount)

    for fish in fishes {
      var newFish = fish
      newFish.updatedAt = Date()
      if visibleSlotsLeft > 0 {
        newFish.isVisible = true
        visibleSlotsLeft -= 1
      } else {
        newFish.isVisible = false
      }
      collectedFish.append(newFish)
      fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    }

    // Update local storage
    saveToLocalStorage()

    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }

    // Sync to Supabase if authenticated
    if supabaseManager.isAuthenticated {
      do {
        try await syncEntireCollectionToSupabase()
      } catch {
        print("❌ Error syncing to Supabase after adding fishes: \(error)")
        throw error
      }
    }
  }

  func getFishByRarity(_ rarity: FishRarity) -> [CollectedFish] {
    return collectedFish.filter { $0.rarity == rarity }
  }

  func getRecentFish(limit: Int = 5) -> [CollectedFish] {
    return Array(collectedFish.suffix(limit))
  }

  func removeFish(_ fish: CollectedFish, fishTankManager: FishTankManager? = nil) async {
    if let index = collectedFish.firstIndex(of: fish) {
      collectedFish.remove(at: index)
      fishCollection[fish.rarity] = max(0, (fishCollection[fish.rarity] ?? 0) - 1)

      // Update local storage
      saveToLocalStorage()

      // Update swimming fish if fishTankManager is provided
      if let manager = fishTankManager {
        manager.updateSwimmingFish(with: getVisibleFish())
      }

      // Sync to Supabase if authenticated
      if supabaseManager.isAuthenticated {
        do {
          try await syncEntireCollectionToSupabase()
        } catch {
          print("❌ Error syncing to Supabase after removing fish: \(error)")
        }
      }
    }
  }

  func clearAllFish(fishTankManager: FishTankManager? = nil) async {
    collectedFish.removeAll()
    initializeFishCollection()

    // Update local storage
    saveToLocalStorage()

    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }

    // Sync to Supabase if authenticated
    if supabaseManager.isAuthenticated {
      do {
        try await syncEntireCollectionToSupabase()
      } catch {
        print("❌ Error syncing to Supabase after clearing fish: \(error)")
      }
    }
  }

  func toggleFishVisibility(_ fish: CollectedFish, fishTankManager: FishTankManager) async -> Bool {
    if let index = collectedFish.firstIndex(of: fish) {
      if !collectedFish[index].isVisible {
        let currentVisibleCount = getVisibleFish().count
        if currentVisibleCount >= AppConfig.maxSwimmingFish {
          return false
        }
      }
      collectedFish[index].isVisible.toggle()
      collectedFish[index].updatedAt = Date()

      // Update local storage
      saveToLocalStorage()

      fishTankManager.updateSwimmingFish(with: getVisibleFish())

      // Sync to Supabase if authenticated
      if supabaseManager.isAuthenticated {
        do {
          try await syncEntireCollectionToSupabase()
        } catch {
          print("❌ Error syncing to Supabase after toggling visibility: \(error)")
        }
      }
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

  func updateFishCollection(_ updatedFish: [CollectedFish]) async {
    collectedFish = updatedFish
    recalculateFishCollection()

    // Update local storage
    saveToLocalStorage()

    // Sync to Supabase if authenticated
    if supabaseManager.isAuthenticated {
      do {
        try await syncEntireCollectionToSupabase()
      } catch {
        print("❌ Error syncing to Supabase after updating collection: \(error)")
      }
    }
  }

  // MARK: - Public Sync Methods

  func triggerSupabaseSync() async {
    print("🔄 GameStateManager: Sync requested")
    if !supabaseManager.isAuthenticated {
      print("⚠️ GameStateManager: Not authenticated, skipping sync")
      return
    }

    print("🔄 GameStateManager: User authenticated, starting sync")
    await mergeCloudAndLocalData()
  }

  // MARK: - Supabase Integration

  private func syncEntireCollectionToSupabase() async throws {
    if !supabaseManager.isAuthenticated {
      print("⚠️ GameStateManager: Not authenticated, skipping Supabase sync")
      return
    }

    print("🔄 GameStateManager: Syncing entire fish collection to Supabase...")
    do {
      try await supabaseManager.saveFishCollection(collectedFish)
      print("✅ GameStateManager: Successfully synced \(collectedFish.count) fish to Supabase")
    } catch {
      print("❌ GameStateManager: Error syncing to Supabase: \(error)")
      throw error
    }
  }
}
