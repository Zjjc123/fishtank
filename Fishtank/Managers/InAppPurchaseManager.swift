//
//  InAppPurchaseManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import StoreKit
import SwiftUI

// MARK: - In App Purchase Manager
@MainActor
final class InAppPurchaseManager: ObservableObject {
  static let shared = InAppPurchaseManager()

  @Published private(set) var isPurchasing = false
  @Published private(set) var isLoadingProducts = false
  @Published private(set) var purchaseError: String?

  private var products: [Product] = []
  private let skipProductID = "dev.jasonzhang.fishtank.skip"

  private init() {
    // Load products when manager is initialized
    Task {
      await loadProducts()
    }
  }

  func ensureProductsLoaded() async {
    if products.isEmpty {
      await loadProducts()
    }
  }

  private func loadProducts() async {
    isLoadingProducts = true
    purchaseError = nil

    do {
      let productIdentifiers = Set([skipProductID])
      products = try await Product.products(for: productIdentifiers)
      print("Loaded \(products.count) products")
    } catch {
      print("Failed to load products: \(error)")
      purchaseError = "Failed to load products: \(error.localizedDescription)"
    }

    isLoadingProducts = false
  }

  @MainActor
  func getSkipPrice(for commitment: FocusCommitment) -> String {
    guard let product = products.first(where: { $0.id == skipProductID }) else {
      return "Loading..."
    }

    return product.displayPrice
  }

  @MainActor
  func purchaseSkip(for commitment: FocusCommitment) async -> Bool {
    guard let product = products.first(where: { $0.id == skipProductID }) else {
      purchaseError = "Skip product not available"
      return false
    }

    isPurchasing = true
    purchaseError = nil

    do {
      let result = try await product.purchase()

      switch result {
      case .success(let verification):
        // Verify the transaction
        switch verification {
        case .verified(let transaction):
          // Handle successful purchase
          await transaction.finish()
          print("Skip purchase successful for \(commitment.rawValue)")
          isPurchasing = false
          return true

        case .unverified(_, let error):
          purchaseError = "Transaction verification failed: \(error.localizedDescription)"
          print("Transaction verification failed: \(error)")
          isPurchasing = false
          return false
        }

      case .userCancelled:
        print("User cancelled skip purchase")
        isPurchasing = false
        return false

      case .pending:
        purchaseError = "Purchase is pending approval"
        print("Purchase is pending approval")
        isPurchasing = false
        return false

      @unknown default:
        purchaseError = "Unknown purchase result"
        print("Unknown purchase result")
        isPurchasing = false
        return false
      }

    } catch {
      purchaseError = "Purchase failed: \(error.localizedDescription)"
      print("Purchase failed: \(error)")
      isPurchasing = false
      return false
    }
  }

  // MARK: - Transaction Management
  @MainActor
  func checkForUnfinishedTransactions() async {
    for await result in Transaction.currentEntitlements {
      switch result {
      case .verified(let transaction):
        // Handle any unfinished transactions
        await transaction.finish()
        print("Finished pending transaction: \(transaction.id)")

      case .unverified(_, let error):
        print("Unverified transaction: \(error)")
      }
    }
  }
}
