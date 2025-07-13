//
//  FishSize.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

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