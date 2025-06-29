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
  private var transactionListener: Task<Void, Error>?

  private init() {
    // Start listening for transactions
    startTransactionListener()

    // Load products when manager is initialized
    Task {
      await loadProducts()
    }
  }

  deinit {
    // Cancel the transaction listener when the manager is deallocated
    transactionListener?.cancel()
  }

  private func startTransactionListener() {
    // Start listening for transactions
    transactionListener = Task.detached {
      // Iterate through any pending transactions
      for await result in StoreKit.Transaction.updates {
        do {
          let transaction = try await result.payloadValue
          // Handle the transaction
          await self.handle(transaction: transaction)

          // Finish the transaction
          await transaction.finish()
        } catch {
          print("Failed to verify transaction: \(error)")
        }
      }
    }
  }

  private func handle(transaction: StoreKit.Transaction) async {
    // Here you can add any additional transaction handling logic
    // For example, you might want to store the transaction ID
    // or update some user entitlements
    print("Handling transaction: \(transaction.id)")
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
          await handle(transaction: transaction)
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
    for await result in StoreKit.Transaction.currentEntitlements {
      switch result {
      case .verified(let transaction):
        // Handle any unfinished transactions
        await handle(transaction: transaction)
        await transaction.finish()
        print("Finished pending transaction: \(transaction.id)")

      case .unverified(_, let error):
        print("Unverified transaction: \(error)")
      }
    }
  }
}
