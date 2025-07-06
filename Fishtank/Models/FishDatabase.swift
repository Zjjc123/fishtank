//
//  FishRarity.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Fish Rarity
enum FishRarity: String, CaseIterable, Codable {
  case common = "Common"
  case uncommon = "Uncommon"
  case rare = "Rare"
  case epic = "Epic"
  case legendary = "Legendary"

  var sortOrder: Int {
    switch self {
    case .common: return 0
    case .uncommon: return 1
    case .rare: return 2
    case .epic: return 3
    case .legendary: return 4
    }
  }

  var color: Color {
    switch self {
    case .common: return .gray
    case .uncommon: return .green
    case .rare: return .blue
    case .epic: return .purple
    case .legendary: return .orange
    }
  }
}

// MARK: - Fish Size
enum FishSize: String, CaseIterable, Codable {
  case tiny = "Tiny"
  case small = "Small"
  case medium = "Medium"
  case large = "Large"
  case huge = "Huge"
  case giant = "Giant"

  var displaySize: CGFloat {
    switch self {
    case .tiny: return 10.0
    case .small: return 20.0
    case .medium: return 30.0
    case .large: return 60.0
    case .huge: return 80.0
    case .giant: return 100.0
    }
  }

  var sortOrder: Int {
    switch self {
    case .tiny: return 0
    case .small: return 1
    case .medium: return 2
    case .large: return 3
    case .huge: return 4
    case .giant: return 5
    }
  }
}

// MARK: - Fish Model
struct Fish: Identifiable, Codable, Hashable {
  let id: UUID
  let name: String
  let imageName: String
  let rarity: FishRarity
  let size: FishSize

  init(name: String, imageName: String, rarity: FishRarity, size: FishSize) {
    self.id = UUID()
    self.name = name
    self.imageName = imageName
    self.rarity = rarity
    self.size = size
  }

  // Custom Codable implementation to handle UUID properly
  enum CodingKeys: String, CodingKey {
    case id, name, imageName, rarity, size
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    imageName = try container.decode(String.self, forKey: .imageName)
    rarity = try container.decode(FishRarity.self, forKey: .rarity)
    size = try container.decode(FishSize.self, forKey: .size)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(imageName, forKey: .imageName)
    try container.encode(rarity, forKey: .rarity)
    try container.encode(size, forKey: .size)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: Fish, rhs: Fish) -> Bool {
    lhs.id == rhs.id
  }
}

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

// MARK: - Legacy Support (for backward compatibility)
extension FishRarity {
  var fishOptions: [(name: String, imageName: String)] {
    return FishDatabase.fishByRarity(self).map { (name: $0.name, imageName: $0.imageName) }
  }

  var imageNames: [String] {
    return fishOptions.map { $0.imageName }
  }

  var names: [String] {
    return fishOptions.map { $0.name }
  }

  static func randomRarity(from lootbox: LootboxType, isSpinner: Bool = false) -> FishRarity {
    let random = Double.random(in: 0...1)
    var cumulative = 0.0

    var probabilities = lootbox.rarityProbabilities

    // If the rarity is a spinner (not winner), we want to increase the chances of getting a legendary or epic fish
    if isSpinner {
      var adjustedProbabilities = probabilities
      adjustedProbabilities[.legendary] = (probabilities[.legendary] ?? 0) * 2
      adjustedProbabilities[.epic] = (probabilities[.epic] ?? 0) * 2
      adjustedProbabilities[.uncommon] = (probabilities[.uncommon] ?? 0) * 0.5
      adjustedProbabilities[.common] = (probabilities[.common] ?? 0) * 0.5
      probabilities = adjustedProbabilities
    }

    for rarity in FishRarity.allCases {
      cumulative += probabilities[rarity] ?? 0
      if random <= cumulative {
        return rarity
      }
    }
    return .common  // Fallback just in case
  }
}
