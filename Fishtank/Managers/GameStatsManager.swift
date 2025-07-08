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

  private let supabaseManager = SupabaseManager.shared
  private var cancellables = Set<AnyCancellable>()

  private init() {
    // Initialize with empty state first
    initializeFishCollection()

    // Listen for authentication state changes
    supabaseManager.$isAuthenticated
      .sink { [weak self] isAuthenticated in
        if isAuthenticated {
          print("🔐 GameStatsManager: User authenticated, fetching from Supabase")
          Task {
            await self?.fetchFromSupabase()
          }
        } else {
          print("🔐 GameStatsManager: User unauthenticated, clearing data")
          self?.collectedFish = []
          self?.initializeFishCollection()
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

  @discardableResult
  func addFish(_ fish: CollectedFish, fishTankManager: FishTankManager? = nil) async throws {
    let currentVisibleCount = getVisibleFish().count
    var newFish = fish
    if currentVisibleCount >= AppConfig.maxSwimmingFish {
      newFish.isVisible = false
    }
    collectedFish.append(newFish)
    fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }
    if supabaseManager.isAuthenticated {
      do {
        try await supabaseManager.saveFishToSupabase(newFish)
      } catch {
        print("❌ Error saving fish to Supabase: \(error)")
        throw error
      }
    }
  }

  @discardableResult
  func addFishes(_ fishes: [CollectedFish], fishTankManager: FishTankManager? = nil) async throws {
    let currentVisibleCount = getVisibleFish().count
    var visibleSlotsLeft = max(0, AppConfig.maxSwimmingFish - currentVisibleCount)
    var newFishes: [CollectedFish] = []
    for fish in fishes {
      var newFish = fish
      if visibleSlotsLeft > 0 {
        newFish.isVisible = true
        visibleSlotsLeft -= 1
      } else {
        newFish.isVisible = false
      }
      newFishes.append(newFish)
      collectedFish.append(newFish)
      fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    }
    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }
    if supabaseManager.isAuthenticated {
      do {
        try await supabaseManager.saveFishesToSupabase(newFishes)
      } catch {
        print("❌ Error saving fishes to Supabase: \(error)")
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

  func removeFish(_ fish: CollectedFish) async {
    if let index = collectedFish.firstIndex(of: fish) {
      let fishToRemove = collectedFish[index]
      collectedFish.remove(at: index)
      fishCollection[fish.rarity] = max(0, (fishCollection[fish.rarity] ?? 0) - 1)
      if supabaseManager.isAuthenticated {
        do {
          try await supabaseManager.deleteFishFromSupabase(fishToRemove.id)
        } catch {
          print("❌ Error deleting fish from Supabase: \(error)")
        }
      }
    }
  }

  func clearAllFish(fishTankManager: FishTankManager? = nil) async {
    let fishIdsToDelete = collectedFish.map { $0.id }
    collectedFish.removeAll()
    initializeFishCollection()
    if let manager = fishTankManager {
      manager.updateSwimmingFish(with: getVisibleFish())
    }
    if supabaseManager.isAuthenticated {
      do {
        try await supabaseManager.deleteAllFishFromSupabase(fishIdsToDelete)
      } catch {
        print("❌ Error deleting all fish from Supabase: \(error)")
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
      let updatedFish = collectedFish[index]
      fishTankManager.updateSwimmingFish(with: getVisibleFish())
      if supabaseManager.isAuthenticated {
        do {
          try await supabaseManager.updateFishVisibilityInSupabase(updatedFish.id, isVisible: updatedFish.isVisible)
        } catch {
          print("❌ Error updating fish visibility in Supabase: \(error)")
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
    if supabaseManager.isAuthenticated {
      do {
        try await supabaseManager.saveFishCollection(collectedFish)
      } catch {
        print("❌ Error updating fish collection in Supabase: \(error)")
      }
    }
  }

  // MARK: - Public Sync Methods

  func triggerSupabaseSync() async {
    if supabaseManager.isAuthenticated {
      await fetchFromSupabase()
    }
  }

  // MARK: - Supabase Integration

  private func fetchFromSupabase() async {
    if isSyncing { return }
    isSyncing = true
    print("🔄 GameStatsManager: Starting Supabase sync...")
    let supabaseFish = await supabaseManager.loadFishCollection()
    print("🔄 GameStatsManager: Fetched \(supabaseFish.count) fish from Supabase")
    await MainActor.run {
      if supabaseManager.isAuthenticated {
        print("🔄 GameStatsManager: User is authenticated, using Supabase data")
        collectedFish = supabaseFish
        recalculateFishCollection()
      }
      print("🔄 GameStatsManager: Sync complete. Total fish: \(collectedFish.count)")
      isSyncing = false
    }
  }
}

