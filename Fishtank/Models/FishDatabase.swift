//
//  FishDatabase.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

// MARK: - Fish Database
struct FishDatabase {
  static let allFish: [Fish] = [
    // Common Fish
    Fish(name: "Minnow", imageName: "Minnow", rarity: .common, size: .tiny),
    Fish(name: "Anchovy", imageName: "Anchovy", rarity: .common, size: .tiny),
    Fish(name: "Tetra", imageName: "Tetra", rarity: .common, size: .small),
    Fish(name: "Perch", imageName: "Perch", rarity: .common, size: .small),
    Fish(name: "Sardine", imageName: "Sardine", rarity: .common, size: .tiny),
    Fish(name: "Mackerel", imageName: "Mackerel", rarity: .common, size: .small),

    // Uncommon Fish
    Fish(name: "Cod", imageName: "Cod", rarity: .uncommon, size: .medium),
    Fish(name: "Pike", imageName: "Pike", rarity: .uncommon, size: .medium),
    Fish(name: "Salmon", imageName: "Salmon", rarity: .uncommon, size: .medium),
    Fish(name: "Guppy", imageName: "Guppy", rarity: .uncommon, size: .small),
    Fish(name: "Goldfish", imageName: "Goldfish", rarity: .uncommon, size: .small),

    // Rare Fish
    Fish(name: "Sturgeon", imageName: "Sturgeon", rarity: .rare, size: .large),
    Fish(name: "Tuna", imageName: "Tuna", rarity: .rare, size: .large),
    Fish(name: "Marlin", imageName: "Marlin", rarity: .rare, size: .large),
    Fish(name: "Barracuda", imageName: "Barracuda", rarity: .rare, size: .medium),

    // Epic Fish
    Fish(name: "Shark", imageName: "Shark", rarity: .epic, size: .huge),
    Fish(name: "Dolphin", imageName: "Dolphin", rarity: .epic, size: .large),

    // Legendary Fish
    Fish(name: "Manta Ray", imageName: "Manta Ray", rarity: .legendary, size: .huge),
    Fish(name: "Blue Whale", imageName: "Blue Whale", rarity: .legendary, size: .giant),
    Fish(name: "Orca", imageName: "Orca", rarity: .legendary, size: .giant),
    Fish(name: "Narwhal", imageName: "Narwhal", rarity: .legendary, size: .large),
  ]

  static func fishByRarity(_ rarity: FishRarity) -> [Fish] {
    return allFish.filter { $0.rarity == rarity }
  }

  static func fishBySize(_ size: FishSize) -> [Fish] {
    return allFish.filter { $0.size == size }
  }

  static func randomFish(from lootbox: LootboxType, isSpinner: Bool = false) -> Fish {
    let rarity = FishRarity.randomRarity(from: lootbox, isSpinner: isSpinner)
    let fishOfRarity = fishByRarity(rarity)
    return fishOfRarity.randomElement()!
  }

  static func randomFish(of rarity: FishRarity) -> Fish {
    let fishOfRarity = fishByRarity(rarity)
    return fishOfRarity.randomElement()!
  }
}
