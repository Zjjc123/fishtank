//
//  LootboxType.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Lootbox Types
enum LootboxType: String, CaseIterable {
  case basic = "Basic"
  case silver = "Silver"
  case gold = "Gold"
  case platinum = "Platinum"

  var color: Color {
    switch self {
    case .basic: return .gray
    case .silver: return .secondary
    case .gold: return .yellow
    case .platinum: return .purple
    }
  }

  var fishCount: Int {
    switch self {
    case .basic: return 1
    case .silver: return 1
    case .gold: return 1
    case .platinum: return 1
    }
  }

  var emoji: String {
    switch self {
    case .basic: return "📦"
    case .silver: return "🎁"
    case .gold: return "💎"
    case .platinum: return "👑"
    }
  }

  var rarityProbabilities: [FishRarity: Double] {
    switch self {
    case .basic:
      return [
        .common: 0.68,
        .uncommon: 0.27,
        .rare: 0.05,
        .epic: 0.00,
        .legendary: 0.00,
      ]
    case .silver:
      return [
        .common: 0.42,
        .uncommon: 0.39,
        .rare: 0.15,
        .epic: 0.03,
        .legendary: 0.00,
      ]
    case .gold:
      return [
        .common: 0.24,
        .uncommon: 0.39,
        .rare: 0.26,
        .epic: 0.09,
        .legendary: 0.02,
      ]
    case .platinum:
      return [
        .common: 0.12,
        .uncommon: 0.32,
        .rare: 0.32,
        .epic: 0.17,
        .legendary: 0.051,
      ]
    }
  }
}
