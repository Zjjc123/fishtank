//
//  CommitmentManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Commitment Manager
@MainActor
final class CommitmentManager: ObservableObject {
  static let shared = CommitmentManager()

  // Dependencies
  private let appRestrictionManager = AppRestrictionManager.shared
  private let notificationManager = NotificationManager.shared
  private let backgroundTaskManager = BackgroundTaskManager.shared
  private let fishTankManager = FishTankManager.shared

  // State
  @Published private(set) var currentCommitment: FocusCommitment?
  @Published private(set) var commitmentStartTime: Date?
  @Published private(set) var isCompleted = false
  @Published private(set) var elapsedTime: TimeInterval = 0
  private var lastUpdateTime = Date()

  // Completion callback
  var onCommitmentCompleted: ((FocusCommitment) -> Void)?

  // MARK: - Timer
  private var completionCheckTimer: Timer?
  private var timerCancellable: AnyCancellable?

  // MARK: - Initialization
  init() {
    // Set up timer to check for commitment completion
    timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        self?.updateProgress()
      }

    // Load saved state
    loadState()
  }

  deinit {
    timerCancellable?.cancel()
  }

  // MARK: - State Management
  private func saveState() {
    let encoder = JSONEncoder()
    
    // Prepare data for saving
    var data: [String: Any] = [:]
    
    if let commitment = currentCommitment {
      data["commitment"] = commitment.rawValue
    }
    
    if let startTime = commitmentStartTime {
      data["startTime"] = startTime.timeIntervalSince1970
    }
    
    // Convert to JSON data
    if let jsonData = try? JSONSerialization.data(withJSONObject: data) {
      UserDefaults.standard.set(jsonData, forKey: "commitmentState")
    }
  }
  
  private func loadState() {
    // Load saved state from UserDefaults
    if let jsonData = UserDefaults.standard.data(forKey: "commitmentState"),
       let data = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
      
      // Load commitment
      if let commitmentString = data["commitment"] as? String,
         let commitment = FocusCommitment(rawValue: commitmentString) {
        currentCommitment = commitment
      }
      
      // Load start time
      if let startTimeInterval = data["startTime"] as? TimeInterval {
        commitmentStartTime = Date(timeIntervalSince1970: startTimeInterval)
      }
      
      // Check if we need to complete the commitment
      if isActive {
        lastUpdateTime = Date()
      }
    }
  }

  // MARK: - Computed Properties
  var progress: Double {
    guard let startTime = commitmentStartTime,
      let commitment = currentCommitment
    else { return 0 }

    // Use the elapsedTime property which is updated with speed boost
    let progressValue = min(elapsedTime / commitment.duration, 1.0)

    // Force progress to 100% if we've exceeded the duration significantly
    if elapsedTime > commitment.duration + 1.0 {
      return 1.0
    }

    return progressValue
  }

  var timeRemaining: TimeInterval {
    guard let commitment = currentCommitment
    else { return 0 }

    // Use the elapsedTime property which is updated with speed boost
    let remaining = max(commitment.duration - elapsedTime, 0)

    // Force remaining time to 0 if we've exceeded the duration
    if elapsedTime > commitment.duration {
      return 0
    }

    return remaining
  }

  var isActive: Bool {
    let active = currentCommitment != nil && commitmentStartTime != nil
    return active
  }

  var isAppRestrictionEnabled: Bool {
    appRestrictionManager.isAuthorized
  }

  // Add this method to CommitmentManager class to calculate progress with speed boost

  // Get the current progress rate (1.0 for normal, higher for speed boost)
  func getProgressRate() -> Double {
    // Check if speed boost is active
    if UserPreferences.shared.hasSpeedBoost {
      return 1.5 // 50% faster progress with speed boost
    }
    return 1.0 // Normal progress rate
  }

  // Update the updateProgress method to use the speed boost
  func updateProgress() {
    guard isActive, let commitment = currentCommitment else { return }
    
    // Calculate elapsed time since last update
    let now = Date()
    let elapsed = now.timeIntervalSince(lastUpdateTime)
    lastUpdateTime = now
    
    // Apply speed boost if active
    let boostedElapsed = elapsed * getProgressRate()
    
    // Update elapsed time only - progress and timeRemaining are computed properties
    elapsedTime += boostedElapsed
    
    // Check for completion
    let currentProgress = min(elapsedTime / commitment.duration, 1.0)
    if currentProgress >= 1.0 && !isCompleted {
      completeCommitment()
    }
  }

  private func completeCommitment() {
    guard let commitment = currentCommitment, !isCompleted else { return }
    
    isCompleted = true
    
    // Session is complete, stop app restriction
    if appRestrictionManager.isRestrictionActive {
      appRestrictionManager.stopAppRestriction()
    }

    // Track completed focus time
    Task {
      await GameStateManager.shared.addFocusTime(commitment.duration)
    }

    // Spawn lootbox reward
    fishTankManager.spawnLootbox(type: commitment.lootboxType)

    // Call completion callback if available
    if let callback = onCommitmentCompleted {
      callback(commitment)
    }
    
    // Clear state after a short delay to allow UI to show completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.currentCommitment = nil
      self?.commitmentStartTime = nil
      self?.isCompleted = false
      self?.saveState()
    }
  }

  func startCommitment(_ commitment: FocusCommitment) {
    currentCommitment = commitment
    commitmentStartTime = Date()
    elapsedTime = 0 // Initialize elapsedTime
    lastUpdateTime = Date() // Initialize lastUpdateTime
    isCompleted = false

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
    elapsedTime = 0
    isCompleted = false
    saveState()

    return cancelled
  }

  func getNextCompletionTime() -> Date? {
    guard let commitment = currentCommitment,
      let startTime = commitmentStartTime,
      isActive
    else { return nil }

    let completionTime = startTime.addingTimeInterval(commitment.duration)
    return completionTime
  }

  func requestAppRestrictionAuthorization() {
    appRestrictionManager.requestAuthorization()
  }
}
