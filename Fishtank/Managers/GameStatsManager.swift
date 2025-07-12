//
//  GameStatsManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Combine
import Supabase
import SwiftUI

// MARK: - Game Stats Manager
@MainActor
final class GameStatsManager: ObservableObject {
  static let shared = GameStatsManager()

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
          print("🔐 GameStatsManager: User authenticated, fetching from Supabase")
          Task {
            await self?.fetchFromSupabase()
          }
        } else {
          print("🔐 GameStatsManager: User unauthenticated, using local data only")
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
      print("💾 GameStatsManager: Saved \(collectedFish.count) fish to local storage")
    } catch {
      print("❌ GameStatsManager: Error saving to local storage: \(error)")
    }
  }

  private func loadFromLocalStorage() {
    guard let data = UserDefaults.standard.data(forKey: localStorageKey) else {
      print("💾 GameStatsManager: No local fish data found")
      return
    }

    do {
      let decoder = JSONDecoder()
      let localFish = try decoder.decode([CollectedFish].self, from: data)
      collectedFish = localFish
      recalculateFishCollection()
      print("💾 GameStatsManager: Loaded \(collectedFish.count) fish from local storage")
    } catch {
      print("❌ GameStatsManager: Error loading from local storage: \(error)")
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
    print("🔄 GameStatsManager: Sync requested")
    if !supabaseManager.isAuthenticated {
      print("⚠️ GameStatsManager: Not authenticated, skipping sync")
      return
    }

    print("🔄 GameStatsManager: User authenticated, starting sync")
    await fetchFromSupabase()
  }

  // MARK: - Supabase Integration

  private func syncEntireCollectionToSupabase() async throws {
    if !supabaseManager.isAuthenticated {
      print("⚠️ GameStatsManager: Not authenticated, skipping Supabase sync")
      return
    }

    print("🔄 GameStatsManager: Syncing entire fish collection to Supabase...")
    do {
      try await supabaseManager.saveFishCollection(collectedFish)
      print("✅ GameStatsManager: Successfully synced \(collectedFish.count) fish to Supabase")
    } catch {
      print("❌ GameStatsManager: Error syncing to Supabase: \(error)")
      throw error
    }
  }

  private func fetchFromSupabase() async {
    if isSyncing {
      print("🔄 GameStatsManager: Already syncing, skipping new sync request")
      return
    }

    isSyncing = true
    print("🔄 GameStatsManager: Starting Supabase sync...")

    if !supabaseManager.isAuthenticated {
      print("⚠️ GameStatsManager: User not authenticated, aborting sync")
      isSyncing = false
      return
    }

    print("🔄 GameStatsManager: User authenticated, proceeding with sync")
    let supabaseFish = await supabaseManager.loadFishCollection()
    print("🔄 GameStatsManager: Fetched \(supabaseFish.count) fish from Supabase")

    await MainActor.run {
      if supabaseManager.isAuthenticated {
        print("🔄 GameStatsManager: User is authenticated, using Supabase data")
        collectedFish = supabaseFish
        recalculateFishCollection()

        // Update local storage with Supabase data
        saveToLocalStorage()

        print("🔄 GameStatsManager: Updated local collection with \(collectedFish.count) fish")

        // Log fish by rarity
        for rarity in FishRarity.allCases {
          let count = fishCollection[rarity] ?? 0
          print("🐠 GameStatsManager: \(rarity.rawValue) fish count: \(count)")
        }
      } else {
        print("⚠️ GameStatsManager: User no longer authenticated during sync, aborting")
      }

      print("🔄 GameStatsManager: Sync complete. Total fish: \(collectedFish.count)")
      isSyncing = false
    }
  }
}
