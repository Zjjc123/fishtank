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

  private let supabaseManager = SupabaseManager.shared
  private var cancellables = Set<AnyCancellable>()

  private init() {
    loadFromStorage()

    // Listen for authentication state changes
    supabaseManager.$isAuthenticated
      .sink { [weak self] isAuthenticated in
        if isAuthenticated {
          Task {
            await self?.triggerSupabaseSync()
          }
        }
      }
      .store(in: &cancellables)
  }

  var fishCount: Int {
    collectedFish.count
  }

  private func loadFromStorage() {
    // Load from local storage first for immediate access
    collectedFish = PersistentStorageManager.loadFish()
    fishCollection = PersistentStorageManager.loadFishCollection()

    // If collection stats are empty but we have fish, recalculate
    if fishCollection.isEmpty && !collectedFish.isEmpty {
      recalculateFishCollection()
    } else if fishCollection.isEmpty {
      initializeFishCollection()
    }

    // If user is authenticated, sync with Supabase
    if supabaseManager.isAuthenticated {
      Task {
        await triggerSupabaseSync()
      }
    }
  }

  private func saveToStorage() {
    PersistentStorageManager.saveFish(collectedFish)
    PersistentStorageManager.saveFishCollection(fishCollection)

    // If user is authenticated, save to Supabase
    if supabaseManager.isAuthenticated {
      Task {
        await supabaseManager.saveFishCollection(collectedFish)
      }
    }
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

  func clearAllFish(fishTankManager: FishTankManager? = nil) {
    collectedFish.removeAll()
    initializeFishCollection()
    saveToStorage()
    // Update swimming fish display if manager provided
    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }
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

  func updateFishCollection(_ updatedFish: [CollectedFish]) {
    collectedFish = updatedFish
    recalculateFishCollection()
    saveToStorage()

    // Sync with Supabase if authenticated
    if supabaseManager.isAuthenticated {
      Task {
        await supabaseManager.saveFishCollection(collectedFish)
      }
    }
  }

  // MARK: - Public Sync Methods

  func triggerSupabaseSync() async {
    await syncWithSupabase()
  }

  // MARK: - Supabase Integration

  private func syncWithSupabase() async {
    let supabaseFish = await supabaseManager.loadFishCollection()

    // Merge local and remote data, preferring the most recent
    var mergedFish: [CollectedFish] = []
    var localFishDict: [UUID: CollectedFish] = [:]
    var remoteFishDict: [UUID: CollectedFish] = [:]

    // Create dictionaries for easy lookup
    for fish in collectedFish {
      localFishDict[fish.id] = fish
    }
    for fish in supabaseFish {
      remoteFishDict[fish.id] = fish
    }

    // Merge fish collections
    let allIds = Set(localFishDict.keys).union(Set(remoteFishDict.keys))

    for id in allIds {
      let localFish = localFishDict[id]
      let remoteFish = remoteFishDict[id]

      if let local = localFish, let remote = remoteFish {
        // Both exist - use the most recent
        mergedFish.append(local.dateCaught > remote.dateCaught ? local : remote)
      } else if let local = localFish {
        // Only local exists
        mergedFish.append(local)
      } else if let remote = remoteFish {
        // Only remote exists
        mergedFish.append(remote)
      }
    }

    // Update the collection
    await MainActor.run {
      collectedFish = mergedFish
      recalculateFishCollection()
      // Save to local storage only, not to Supabase to avoid infinite loop
      PersistentStorageManager.saveFish(collectedFish)
      PersistentStorageManager.saveFishCollection(fishCollection)
    }
  }
}
