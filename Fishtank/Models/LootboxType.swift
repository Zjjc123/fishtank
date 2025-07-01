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

  var rarityBoost: Double {
    switch self {
    case .basic: return 1
    case .silver: return 3
    case .gold: return 8
    case .platinum: return 15
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
}
