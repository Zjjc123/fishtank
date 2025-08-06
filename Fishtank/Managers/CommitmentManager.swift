//
//  CommitmentManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Combine
import Foundation
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

  // Keys for UserDefaults
  private let commitmentStateKey = "commitmentState"
  private let commitmentTypeKey = "commitmentType"
  private let startTimeKey = "startTime"
  private let elapsedTimeKey = "elapsedTime"
  private let lastSaveTimeKey = "lastSaveTime"

  // Completion callback
  var onCommitmentCompleted: ((FocusCommitment) -> Void)?

  // MARK: - Timer
  private var timerCancellable: AnyCancellable?

  // MARK: - Initialization
  init() {
    // Load saved state first
    loadState()

    // Set up timer to check for commitment completion
    timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        self?.updateProgress()
      }

    // Register for app lifecycle notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  deinit {
    timerCancellable?.cancel()
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - App Lifecycle
  @objc private func appWillResignActive() {
    // Save state when app goes to background
    saveState()
  }

  @objc private func appDidBecomeActive() {
    // Update progress when app comes to foreground
    if isActive {
      // First check if commitment should be completed based on current state
      checkAndCompleteCommitment()
      
      // Then update progress for background time
      updateProgressAfterBackground()
    }
  }

  // MARK: - State Management
  private func saveState() {
    let defaults = UserDefaults.standard

    // Save commitment type
    if let commitment = currentCommitment {
      defaults.set(commitment.rawValue, forKey: commitmentTypeKey)
    } else {
      defaults.removeObject(forKey: commitmentTypeKey)
    }

    // Save start time
    if let startTime = commitmentStartTime {
      defaults.set(startTime.timeIntervalSince1970, forKey: startTimeKey)
    } else {
      defaults.removeObject(forKey: startTimeKey)
    }

    // Save elapsed time
    defaults.set(elapsedTime, forKey: elapsedTimeKey)

    // Save current time as last save time
    defaults.set(Date().timeIntervalSince1970, forKey: lastSaveTimeKey)

    // Synchronize to ensure data is saved immediately
    defaults.synchronize()
  }

  private func loadState() {
    let defaults = UserDefaults.standard
    
    // Check if there's a pending commitment completion from background task
    let pendingCompletion = defaults.bool(forKey: "pendingCommitmentCompletion")
    if pendingCompletion {
      if let commitmentString = defaults.string(forKey: "pendingCommitmentType"),
         let commitment = FocusCommitment(rawValue: commitmentString) {
        // Set the commitment as completed
        currentCommitment = commitment
        elapsedTime = commitment.duration
        isCompleted = true
        
        // Clear the pending completion flags
        defaults.removeObject(forKey: "pendingCommitmentCompletion")
        defaults.removeObject(forKey: "pendingCommitmentType")
        defaults.synchronize()
        
        // Reset the commitment after a short delay to allow UI to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
          self?.resetCommitment()
        }
        
        // Exit early since we've handled this special case
        return
      }
    }

    // Load commitment type
    if let commitmentString = defaults.string(forKey: commitmentTypeKey),
      let commitment = FocusCommitment(rawValue: commitmentString)
    {
      currentCommitment = commitment
    }

    // Load start time
    if let startTimeInterval = defaults.object(forKey: startTimeKey) as? TimeInterval {
      commitmentStartTime = Date(timeIntervalSince1970: startTimeInterval)
    }

    // Load elapsed time
    elapsedTime = defaults.double(forKey: elapsedTimeKey)
    
    // Check if commitment should be completed immediately after loading state
    if isActive {
      // First check if the commitment should be completed based on loaded state
      checkAndCompleteCommitment()
      
      // Then update progress based on time passed while app was closed
      updateProgressAfterBackground()
    }
  }

  private func updateProgressAfterBackground() {
    guard let commitment = currentCommitment else { return }

    let defaults = UserDefaults.standard

    // Get the last time we saved state
    if let lastSaveTimeInterval = defaults.object(forKey: lastSaveTimeKey) as? TimeInterval {
      let lastSaveTime = Date(timeIntervalSince1970: lastSaveTimeInterval)
      let now = Date()

      // Calculate time passed since last save
      let timeSinceLastSave = now.timeIntervalSince(lastSaveTime)

      if timeSinceLastSave > 0 {
        // Apply speed boost to the background time
        let boostedBackgroundTime = timeSinceLastSave * getProgressRate()

        // Add the background time to elapsed time
        elapsedTime += boostedBackgroundTime
        
        // Check if commitment should be completed
        checkAndCompleteCommitment()
      }
    }

    // Update lastUpdateTime to now
    lastUpdateTime = Date()
  }
  
  // New helper method to centralize commitment completion check
  private func checkAndCompleteCommitment() {
    guard let commitment = currentCommitment, !isCompleted else { return }
    
    // Check if elapsed time has reached or exceeded the commitment duration
    if elapsedTime >= commitment.duration {
      completeCommitment()
    }
  }

  // MARK: - Computed Properties
  var progress: Double {
    guard let commitment = currentCommitment else { return 0 }

    // Calculate progress based on elapsed time
    let progressValue = min(elapsedTime / commitment.duration, 1.0)

    // Force progress to 100% if we've exceeded the duration significantly
    if elapsedTime > commitment.duration + 1.0 {
      return 1.0
    }

    return progressValue
  }

  var timeRemaining: TimeInterval {
    guard let commitment = currentCommitment else { return 0 }

    // Calculate remaining time based on elapsed time
    let remaining = max(commitment.duration - elapsedTime, 0)

    // Force remaining time to 0 if we've exceeded the duration
    if elapsedTime > commitment.duration {
      return 0
    }

    return remaining
  }

  var isActive: Bool {
    return currentCommitment != nil && commitmentStartTime != nil && !isCompleted
  }

  var isAppRestrictionEnabled: Bool {
    return appRestrictionManager.isAuthorized
  }

  // Get the current progress rate (1.0 for normal, higher for speed boost)
  func getProgressRate() -> Double {
    // Check if speed boost is active
    if UserPreferences.shared.hasSpeedBoost {
      return 1.5  // 50% faster progress with speed boost
    }
    return 1.0  // Normal progress rate
  }

  // Update progress during active app usage
  func updateProgress() {
    guard isActive, !isCompleted else { return }

    // Calculate elapsed time since last update
    let now = Date()
    let elapsed = now.timeIntervalSince(lastUpdateTime)
    lastUpdateTime = now

    // Apply speed boost if active
    let boostedElapsed = elapsed * getProgressRate()

    // Update elapsed time
    elapsedTime += boostedElapsed

    // Check for completion using the centralized method
    checkAndCompleteCommitment()
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
      self?.resetCommitment()
    }
  }

  private func resetCommitment() {
    currentCommitment = nil
    commitmentStartTime = nil
    elapsedTime = 0
    isCompleted = false
    saveState()
  }

  func startCommitment(_ commitment: FocusCommitment) {
    currentCommitment = commitment
    commitmentStartTime = Date()
    elapsedTime = 0
    lastUpdateTime = Date()
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

    // Reset state
    resetCommitment()

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
