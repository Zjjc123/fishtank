//
//  CommitmentManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Commitment Manager
@MainActor
final class CommitmentManager: ObservableObject {
  static let shared = CommitmentManager()
  
  @Published var currentCommitment: FocusCommitment?
  @Published var commitmentStartTime: Date?
  private let appRestrictionManager = AppRestrictionManager.shared
  private let purchaseManager = InAppPurchaseManager.shared
  private let notificationManager = NotificationManager.shared
  private let backgroundTaskManager = BackgroundTaskManager.shared

  private init() {
    // Load any saved state
    loadState()
  }

  private func loadState() {
    if let savedCommitmentData = UserDefaults.standard.dictionary(forKey: "CurrentCommitment"),
       let commitmentString = savedCommitmentData["commitment"] as? String,
       let commitment = FocusCommitment(rawValue: commitmentString),
       let startTimeInterval = savedCommitmentData["startTime"] as? TimeInterval
    {
      currentCommitment = commitment
      commitmentStartTime = Date(timeIntervalSince1970: startTimeInterval)
      
      // If we have an active commitment, make sure app restrictions are active
      if isActive && appRestrictionManager.isAuthorized {
        appRestrictionManager.startAppRestriction()
      }
    }
  }

  private func saveState() {
    if let commitment = currentCommitment, let startTime = commitmentStartTime {
      let commitmentData: [String: Any] = [
        "commitment": commitment.rawValue,
        "startTime": startTime.timeIntervalSince1970
      ]
      UserDefaults.standard.set(commitmentData, forKey: "CurrentCommitment")
    } else {
      UserDefaults.standard.removeObject(forKey: "CurrentCommitment")
    }
  }

  var progress: Double {
    guard let startTime = commitmentStartTime,
          let commitment = currentCommitment
    else { return 0 }
    
    let elapsedTime = Date().timeIntervalSince(startTime)
    return min(elapsedTime / commitment.duration, 1.0)
  }

  var timeRemaining: TimeInterval {
    guard let startTime = commitmentStartTime,
          let commitment = currentCommitment
    else { return 0 }
    
    let elapsedTime = Date().timeIntervalSince(startTime)
    return max(commitment.duration - elapsedTime, 0)
  }

  var isActive: Bool {
    currentCommitment != nil && commitmentStartTime != nil
  }

  var isAppRestrictionEnabled: Bool {
    appRestrictionManager.isAuthorized
  }

  // MARK: - Purchase-related computed properties
  var isPurchasing: Bool {
    purchaseManager.isPurchasing
  }

  var isLoadingProducts: Bool {
    purchaseManager.isLoadingProducts
  }

  var purchaseError: String? {
    purchaseManager.purchaseError
  }

  func getSkipPrice(for commitment: FocusCommitment) -> String {
    purchaseManager.getSkipPrice(for: commitment)
  }

  func getPurchaseError() -> String? {
    purchaseManager.purchaseError
  }

  func ensureProductsLoaded() async {
    await purchaseManager.ensureProductsLoaded()
  }

  func startCommitment(_ commitment: FocusCommitment) {
    currentCommitment = commitment
    commitmentStartTime = Date()
    
    // Start app restriction if authorized
    if appRestrictionManager.isAuthorized {
      appRestrictionManager.startAppRestriction()
    }
    
    // Schedule background task for completion
    let completionTime = Date().addingTimeInterval(commitment.duration)
    backgroundTaskManager.scheduleBackgroundTask(for: completionTime)
    
    // Save state
    saveState()
  }

  func cancelCommitment() -> FocusCommitment? {
    let cancelled = currentCommitment
    
    // Stop app restriction
    if appRestrictionManager.isRestrictionActive {
      appRestrictionManager.stopAppRestriction()
    }
    
    // Cancel any pending notifications
    notificationManager.cancelAllPendingNotifications()
    
    // Clear state
    currentCommitment = nil
    commitmentStartTime = nil
    saveState()
    
    return cancelled
  }

  func checkBackgroundProgress() -> FocusCommitment? {
    guard let commitment = currentCommitment,
          let startTime = commitmentStartTime,
          isActive
    else { return nil }
    
    let elapsedTime = Date().timeIntervalSince(startTime)
    if elapsedTime >= commitment.duration {
      // Session is complete, stop app restriction
      if appRestrictionManager.isRestrictionActive {
        appRestrictionManager.stopAppRestriction()
      }
      
      // Clear state
      let completed = currentCommitment
      currentCommitment = nil
      commitmentStartTime = nil
      saveState()
      
      return completed
    }
    
    return nil
  }

  func getNextCompletionTime() -> Date? {
    guard let commitment = currentCommitment,
          let startTime = commitmentStartTime,
          isActive
    else { return nil }
    
    return startTime.addingTimeInterval(commitment.duration)
  }

  func requestAppRestrictionAuthorization() {
    appRestrictionManager.requestAuthorization()
  }

  // MARK: - Skip functionality
  func skipCommitmentWithPurchase() async -> FocusCommitment? {
    guard let commitment = currentCommitment else { return nil }

    let success = await purchaseManager.purchaseSkip(for: commitment)
    
    if success {
      // Purchase successful, complete the commitment
      let skippedCommitment = commitment
      currentCommitment = nil
      commitmentStartTime = nil

      // Stop app restriction
      appRestrictionManager.stopAppRestriction()

      // Cancel any pending notifications
      notificationManager.cancelAllPendingNotifications()

      return skippedCommitment
    }

    return nil
  }

} 