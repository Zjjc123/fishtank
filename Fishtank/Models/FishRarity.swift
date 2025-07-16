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
  
  var emoji: String {
    switch self {
    case .common: return "⚪️"
    case .uncommon: return "🟢"
    case .rare: return "🔵"
    case .epic: return "🟣"
    case .legendary: return "🟠"
    }
  }
}

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