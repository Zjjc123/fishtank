//
//  CommitmentManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Commitment Manager
class CommitmentManager: ObservableObject {
  @Published var currentCommitment: FocusCommitment?
  @Published var commitmentStartTime: Date?
  private let appRestrictionManager = AppRestrictionManager()

  var progress: Double {
    guard let commitment = currentCommitment,
      let startTime = commitmentStartTime
    else { return 0 }

    let elapsed = Date().timeIntervalSince(startTime)
    return min(elapsed / commitment.duration, 1.0)
  }

  var timeRemaining: TimeInterval {
    guard let commitment = currentCommitment,
      let startTime = commitmentStartTime
    else { return 0 }

    let elapsed = Date().timeIntervalSince(startTime)
    return max(commitment.duration - elapsed, 0)
  }

  var isActive: Bool {
    currentCommitment != nil
  }

  var isAppRestrictionEnabled: Bool {
    appRestrictionManager.isAuthorized
  }

  func startCommitment(_ commitment: FocusCommitment) {
    currentCommitment = commitment
    commitmentStartTime = Date()

    // Start app restriction if authorized
    if appRestrictionManager.isAuthorized {
      appRestrictionManager.startAppRestriction()
    }
  }

  func cancelCommitment() -> FocusCommitment? {
    let cancelledCommitment = currentCommitment
    currentCommitment = nil
    commitmentStartTime = nil

    // Stop app restriction
    appRestrictionManager.stopAppRestriction()

    return cancelledCommitment
  }

  func checkProgress() -> FocusCommitment? {
    guard let commitment = currentCommitment,
      let startTime = commitmentStartTime
    else { return nil }

    let elapsed = Date().timeIntervalSince(startTime)

    if elapsed >= commitment.duration {
      let completedCommitment = commitment
      currentCommitment = nil
      commitmentStartTime = nil

      // Stop app restriction when commitment is completed
      appRestrictionManager.stopAppRestriction()

      return completedCommitment
    }

    return nil
  }

  func requestAppRestrictionAuthorization() {
    appRestrictionManager.requestAuthorization()
  }

  func debugFinishCommitment() -> FocusCommitment? {
    guard let commitment = currentCommitment else { return nil }

    // Set start time to a point in the past that would make the commitment complete
    commitmentStartTime = Date().addingTimeInterval(-commitment.duration - 1)

    // Check progress immediately to trigger completion
    return checkProgress()
  }
} 