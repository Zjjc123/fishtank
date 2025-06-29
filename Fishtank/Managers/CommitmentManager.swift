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
  @Published var currentCommitment: FocusCommitment?
  @Published var commitmentStartTime: Date?
  private let appRestrictionManager = AppRestrictionManager()
  private let purchaseManager = InAppPurchaseManager.shared

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

      return skippedCommitment
    }

    return nil
  }

  func debugFinishCommitment() -> FocusCommitment? {
    guard let commitment = currentCommitment else { return nil }

    // Set start time to a point in the past that would make the commitment complete
    commitmentStartTime = Date().addingTimeInterval(-commitment.duration - 1)

    // Check progress immediately to trigger completion
    return checkProgress()
  }
} 