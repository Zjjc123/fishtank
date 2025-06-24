//
//  AppRestrictionManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

// MARK: - App Restriction Manager
class AppRestrictionManager: ObservableObject {
  @Published var isRestrictionActive = false
  private let store = ManagedSettingsStore()
  private let center = AuthorizationCenter.shared

  init() {
    // Request authorization when the manager is initialized
    requestAuthorization()
  }

  func requestAuthorization() {
    Task {
      do {
        try await center.requestAuthorization(for: .individual)
        print("Screen Time authorization granted")
      } catch {
        print("Screen Time authorization failed: \(error)")
      }
    }
  }

  func startAppRestriction() {
    guard center.authorizationStatus == .approved else {
      print("Screen Time authorization not approved")
      return
    }

    // Shield all app categories. The system prevents the app that sets the restriction from being blocked.
    store.shield.applicationCategories = .all()

    isRestrictionActive = true
    print("App restriction started")
  }

  func stopAppRestriction() {
    // Remove all restrictions
    store.shield.applicationCategories = nil
    store.shield.applications = nil

    isRestrictionActive = false
    print("App restriction stopped")
  }

  var isAuthorized: Bool {
    center.authorizationStatus == .approved
  }
} 