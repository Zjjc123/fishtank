//
//  UserPreferences.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation
import SwiftUI

// MARK: - User Preferences
class UserPreferences: ObservableObject {
  static let shared = UserPreferences()
  
  // Keys for UserDefaults
  private let hasSpeedBoostKey = "hasSpeedBoost"
  private let speedBoostExpirationKey = "speedBoostExpiration"
  private let hasSeenHelpPopupKey = "hasSeenHelpPopup"
  
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
  
  @Published var hasSpeedBoost: Bool {
    didSet {
      UserDefaults.standard.set(hasSpeedBoost, forKey: hasSpeedBoostKey)
    }
  }
  
  @Published var speedBoostExpiration: Date? {
    didSet {
      if let date = speedBoostExpiration {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: speedBoostExpirationKey)
      } else {
        UserDefaults.standard.removeObject(forKey: speedBoostExpirationKey)
      }
    }
  }
  
  @Published var hasSeenHelpPopup: Bool {
    didSet {
      UserDefaults.standard.set(hasSeenHelpPopup, forKey: hasSeenHelpPopupKey)
    }
  }
  
  private init() {
    // Load saved background color preference or use blue if not set
    let savedColorValue = UserDefaults.standard.string(forKey: "selectedBackgroundColor") ?? BackgroundColorOption.blue.rawValue
    self.selectedBackgroundColor = BackgroundColorOption(rawValue: savedColorValue) ?? .blue
    
    // Load unlocked backgrounds status
    self.unlockedBackgrounds = UserDefaults.standard.bool(forKey: "unlockedBackgrounds")
    
    // Load speed boost status
    self.hasSpeedBoost = UserDefaults.standard.bool(forKey: hasSpeedBoostKey)
    
    // Load speed boost expiration date
    let expirationTimeInterval = UserDefaults.standard.double(forKey: speedBoostExpirationKey)
    self.speedBoostExpiration = expirationTimeInterval > 0 ? 
      Date(timeIntervalSince1970: expirationTimeInterval) : nil
    
    // Load whether user has seen help popup
    self.hasSeenHelpPopup = UserDefaults.standard.bool(forKey: hasSeenHelpPopupKey)
    
    // Check if speed boost has expired
    checkSpeedBoostExpiration()
    
    // Start timer to check expiration periodically
    Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
      self?.checkSpeedBoostExpiration()
    }
  }
  
  // Calculate remaining time for speed boost
  func speedBoostTimeRemaining() -> TimeInterval? {
    guard hasSpeedBoost, let expirationDate = speedBoostExpiration else {
      return nil
    }
    
    let remaining = expirationDate.timeIntervalSince(Date())
    return remaining > 0 ? remaining : nil
  }
  
  // Format speed boost time remaining as a string
  func formattedSpeedBoostTimeRemaining() -> String {
    guard let remaining = speedBoostTimeRemaining() else {
      return "No active boost"
    }
    
    let hours = Int(remaining) / 3600
    let minutes = (Int(remaining) % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m remaining"
    } else {
      return "\(minutes)m remaining"
    }
  }
  
  // Activate speed boost for 24 hours
  func activateSpeedBoost() {
    self.hasSpeedBoost = true
    self.speedBoostExpiration = Date().addingTimeInterval(24 * 3600) // 24 hours
  }
  
  private func checkSpeedBoostExpiration() {
    if let expirationDate = speedBoostExpiration, expirationDate < Date() {
      self.hasSpeedBoost = false
      self.speedBoostExpiration = nil
    }
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