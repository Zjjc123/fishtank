//
//  AppConfig.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

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
}
