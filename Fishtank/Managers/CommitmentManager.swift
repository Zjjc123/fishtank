//
//  CommitmentManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Combine
import SwiftUI

// MARK: - Commitment Manager
@MainActor
final class CommitmentManager: ObservableObject {
  static let shared = CommitmentManager()

  @Published var currentCommitment: FocusCommitment?
  @Published var commitmentStartTime: Date?

  // MARK: - Dependencies
  private let appRestrictionManager = AppRestrictionManager.shared
  private let purchaseManager = InAppPurchaseManager.shared
  private let notificationManager = NotificationManager.shared
  private let backgroundTaskManager = BackgroundTaskManager.shared
  private let fishTankManager = FishTankManager.shared

  // MARK: - Timer
  private var completionCheckTimer: Timer?
  private var timerCancellable: AnyCancellable?

  // MARK: - Completion Callback
  var onCommitmentCompleted: ((FocusCommitment) -> Void)?

  // MARK: - Initialization
  private init() {
    loadState()
    setupCompletionCheckTimer()
  }

  deinit {
    timerCancellable?.cancel()
  }

  // Setup a timer to periodically check if the commitment should be completed
  private func setupCompletionCheckTimer() {
    // Cancel any existing timer
    timerCancellable?.cancel()

    // Create a timer that fires every second
    let timer = Timer.publish(every: 1, on: .main, in: .common)

    // Connect and store the cancellable
    let connected = timer.connect()

    // Subscribe to the timer events
    let subscription =
      timer
      .sink { [weak self] _ in
        guard let self = self else { return }

        // Only check if there's an active commitment
        if self.isActive {
          let _ = self.checkBackgroundProgress()
        }
      }

    // Store both cancellables in a single one
    timerCancellable = AnyCancellable {
      subscription.cancel()
      connected.cancel()
    }
  }

  // MARK: - State Management
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
        "startTime": startTime.timeIntervalSince1970,
      ]
      UserDefaults.standard.set(commitmentData, forKey: "CurrentCommitment")
    } else {
      UserDefaults.standard.removeObject(forKey: "CurrentCommitment")
    }
  }

  // MARK: - Computed Properties
  var progress: Double {
    guard let startTime = commitmentStartTime,
      let commitment = currentCommitment
    else { return 0 }

    let elapsedTime = Date().timeIntervalSince(startTime)
    let progressValue = min(elapsedTime / commitment.duration, 1.0)

    // Force progress to 100% if we've exceeded the duration significantly
    if elapsedTime > commitment.duration + 1.0 {
      return 1.0
    }

    return progressValue
  }

  var timeRemaining: TimeInterval {
    guard let startTime = commitmentStartTime,
      let commitment = currentCommitment
    else { return 0 }

    let elapsedTime = Date().timeIntervalSince(startTime)
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

  // MARK: - Purchase Properties
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
    let remainingTime = max(commitment.duration - elapsedTime, 0)

    // Check if commitment should be completed
    // Use a small epsilon value to account for floating point precision issues
    let epsilon = 0.001

    // Commitment should complete if:
    // 1. Elapsed time exceeds commitment duration, or
    // 2. Remaining time is 0 or less, or
    // 3. Progress is at or above 100%
    let shouldComplete =
      elapsedTime >= (commitment.duration - epsilon) || remainingTime <= epsilon
      || (elapsedTime / commitment.duration) >= 1.0

    if shouldComplete {
      // Session is complete, stop app restriction
      if appRestrictionManager.isRestrictionActive {
        appRestrictionManager.stopAppRestriction()
      }

      // Clear state
      let completed = currentCommitment
      currentCommitment = nil
      commitmentStartTime = nil
      saveState()

      // Track completed focus time
      Task {
        await GameStateManager.shared.addFocusTime(commitment.duration)
      }

      // Spawn lootbox reward
      fishTankManager.spawnLootbox(type: commitment.lootboxType)

      // Call completion callback if available
      if let completed = completed, let callback = onCommitmentCompleted {
        callback(completed)
      }

      return completed
    }

    return nil
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

  // MARK: - Skip Functionality
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

      // Save state to persist the skipped session
      saveState()

      // Track focus time for skipped sessions
      Task {
        await GameStateManager.shared.addFocusTime(commitment.duration)
      }

      // Spawn lootbox reward
      fishTankManager.spawnLootbox(type: commitment.lootboxType)

      return skippedCommitment
    }

    return nil
  }
}
