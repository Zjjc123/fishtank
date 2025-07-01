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

  var probability: Double {
    switch self {
    case .common: return 0.50
    case .uncommon: return 0.30
    case .rare: return 0.15
    case .epic: return 0.04
    case .legendary: return 0.01
    }
  }

  var fishOptions: [(name: String, imageName: String)] {
    switch self {
    case .common:
      return [
        ("Minnow", "Minnow"),
        ("Anchovy", "Anchovy"),
        ("Tetra", "Tetra"),
        ("Perch", "Perch"),
        ("Sardine", "Sardine"),
        ("Mackerel", "Mackerel"),
      ]
    case .uncommon:
      return [
        ("Cod", "Cod"),
        ("Pike", "Pike"),
        ("Salmon", "Salmon"),
        ("Guppy", "Guppy"),
        ("Goldfish", "Goldfish"),
      ]
    case .rare:
      return [
        ("Sturgeon", "Sturgeon"),
        ("Tuna", "Tuna"),
        ("Marlin", "Marlin"),
        ("Barracuda", "Barracuda"),
      ]
    case .epic:
      return [
        ("Shark", "Shark"),
        ("Dolphin", "Dolphin"),
      ]
    case .legendary:
      return [
        ("Manta Ray", "Manta Ray"),
        ("Blue Whale", "Blue Whale"),
        ("Orca", "Orca"),
        ("Narwhal", "Narwhal"),
      ]
    }
  }

  var imageNames: [String] {
    fishOptions.map { $0.imageName }
  }

  var names: [String] {
    fishOptions.map { $0.name }
  }

  static func randomRarity(boost: Double = 1.0) -> FishRarity {
    let random = Double.random(in: 0...1)
    var cumulative = 0.0

    let boostedProbabilities = FishRarity.allCases.map { rarity in
      switch rarity {
      case .common:
        return max(0.1, rarity.probability / boost)
      case .legendary:
        return min(0.01, rarity.probability * boost)
      default:
        return min(0.4, rarity.probability * (1 + (boost - 1) * 0.5))
      }
    }

    let total = boostedProbabilities.reduce(0, +)
    let normalizedProbabilities = boostedProbabilities.map { $0 / total }

    for (index, probability) in normalizedProbabilities.enumerated() {
      cumulative += probability
      if random <= cumulative {
        return FishRarity.allCases[index]
      }
    }
    return .common
  }
}
