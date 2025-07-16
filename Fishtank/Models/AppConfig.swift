//
//  AppConfig.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation
import SwiftUI

// MARK: - Configuration
struct AppConfig {
  static let rewardDisplayDuration: TimeInterval = 2
  static let maxSwimmingFish = 20
  
  // MARK: - App Version
  static var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }
  
  static var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
  }
  
  static var versionAndBuild: String {
    "v\(appVersion) (\(buildNumber))"
  }
  
  // MARK: - In-App Purchase IDs
  static let backgroundsProductID = "dev.jasonzhang.fishtank.backgrounds"
}

// MARK: - User Preferences
class UserPreferences: ObservableObject {
  static let shared = UserPreferences()
  
  @Published var selectedBackgroundColor: BackgroundColorOption {
    didSet {
      UserDefaults.standard.set(selectedBackgroundColor.rawValue, forKey: "selectedBackgroundColor")
    }
  }
  
  @Published var unlockedBackgrounds: Bool {
    didSet {
      UserDefaults.standard.set(unlockedBackgrounds, forKey: "unlockedBackgrounds")
    }
  }
  
  private init() {
    // Load saved background color preference or use blue if not set
    let savedColorValue = UserDefaults.standard.string(forKey: "selectedBackgroundColor") ?? BackgroundColorOption.blue.rawValue
    self.selectedBackgroundColor = BackgroundColorOption(rawValue: savedColorValue) ?? .blue
    
    // Load unlocked backgrounds status
    self.unlockedBackgrounds = UserDefaults.standard.bool(forKey: "unlockedBackgrounds")
  }
}

// Background color options
enum BackgroundColorOption: String, CaseIterable, Identifiable {
  case blue = "Blue"
  case purple = "Purple"
  case teal = "Teal"
  case green = "Green"
  case orange = "Orange"
  case pink = "Pink"
  
  var id: String { self.rawValue }
  
  var requiresPurchase: Bool {
    switch self {
    case .blue:
      return false // Blue is always free
    default:
      return true // All other colors require purchase
    }
  }
  
  var colors: (top: Color, bottom: Color) {
    switch self {
    case .blue:
      return (Color.cyan.opacity(0.6), Color.blue.opacity(0.7))
    case .purple:
      return (Color.purple.opacity(0.4), Color.blue.opacity(0.6))
    case .teal:
      return (Color.teal.opacity(0.5), Color.blue.opacity(0.5))
    case .green:
      return (Color.green.opacity(0.3), Color.teal.opacity(0.5))
    case .orange:
      return (Color.orange.opacity(0.4), Color.yellow.opacity(0.3))
    case .pink:
      return (Color.pink.opacity(0.4), Color.purple.opacity(0.3))
    }
  }
}
