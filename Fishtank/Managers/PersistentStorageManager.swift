//
//  PersistentStorageManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

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