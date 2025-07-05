//
//  FocusCommitment.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

// MARK: - Focus Commitment
enum FocusCommitment: String, CaseIterable {
  case short = "15 Minutes"
  case medium = "30 Minutes"
  case long = "1 Hour"
  case veryLong = "2 Hours"

  var duration: TimeInterval {
    switch self {
    case .short: return 900
    case .medium: return 1800
    case .long: return 3600
    case .veryLong: return 7200
    }
  }

  var lootboxType: LootboxType {
    switch self {
    case .short: return .basic
    case .medium: return .silver
    case .long: return .gold
    case .veryLong: return .platinum
    }
  }

  var iconName: String {
    switch self {
    case .short: return "timer"
    case .medium: return "alarm"
    case .long: return "clock"
    case .veryLong: return "clock.badge"
    }
  }
}
