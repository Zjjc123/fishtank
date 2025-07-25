//
//  StoreView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import StoreKit
import SwiftUI

struct StoreView: View {
  @Binding var isPresented: Bool
  @StateObject private var iapManager = InAppPurchaseManager.shared
  @ObservedObject private var userPreferences = UserPreferences.shared
  @ObservedObject private var fishTankManager = FishTankManager.shared
  @State private var isPurchasing = false
  @State private var showPurchaseSuccess = false
  @State private var purchaseSuccessMessage = ""

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
          Text("Store")
            .font(.title2)
            .fontWeight(.bold)

          storeItemsView

          Spacer()

          // Restore purchases button
          Button(action: {
            Task {
              await iapManager.restorePurchases()
            }
          }) {
            Text("Restore Purchases")
              .font(.footnote)
              .foregroundColor(.secondary)
          }
          .padding(.bottom)
        }
        .padding(.top, 10)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
              isPresented = false
            }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
            }
          }
        }

        // Purchase success overlay
        if showPurchaseSuccess {
          purchaseSuccessOverlay
        }

        // Loading overlay
        if isPurchasing || iapManager.isPurchasing {
          loadingOverlay
        }
      }
      .onAppear {
        Task {
          await iapManager.ensureProductsLoaded()
        }
      }
    }
  }

  // Combined store items view
  private var storeItemsView: some View {
    VStack(spacing: 20) {
      // Platinum lootbox card
      storeItemCard(
        title: "Platinum Lootbox",
        description: "Highest chance for rare and legendary fish!",
        icon: "👑",
        price: iapManager.getPlatinumLootboxPrice(),
        action: {
          purchasePlatinumLootbox()
        }
      )

      // Current boost status
      if userPreferences.hasSpeedBoost {
        VStack {
          Text("Active Speed Boost")
            .font(.headline)
            .foregroundColor(.green)

          Text(userPreferences.formattedSpeedBoostTimeRemaining())
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
      }

      // Speed boost card
      storeItemCard(
        title: "Speed Boost (24 Hours)",
        description: "Complete commitments 50% faster for 24 hours!",
        icon: "⚡️",
        price: iapManager.getSpeedBoostPrice(),
        action: {
          purchaseSpeedBoost()
        }
      )
    }
    .padding()
  }

  // Reusable store item card
  private func storeItemCard(
    title: String, description: String, icon: String, price: String, action: @escaping () -> Void
  ) -> some View {
    VStack {
      HStack(spacing: 15) {
        Text(icon)
          .font(.system(size: 40))

        VStack(alignment: .leading) {
          Text(title)
            .font(.headline)

          Text(description)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        Spacer()

        Button(action: action) {
          Text(price)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isPurchasing)
      }
      .padding()
      .background(Color.white.opacity(0.1))
      .cornerRadius(12)
    }
  }

  // Purchase success overlay
  private var purchaseSuccessOverlay: some View {
    ZStack {
      Color.black.opacity(0.6)
        .ignoresSafeArea()

      VStack(spacing: 20) {
        Text("Purchase Successful!")
          .font(.headline)
          .foregroundColor(.white)

        Text(purchaseSuccessMessage)
          .multilineTextAlignment(.center)
          .foregroundColor(.white)

        Button(action: {
          withAnimation {
            showPurchaseSuccess = false
          }
        }) {
          Text("OK")
            .fontWeight(.bold)
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
      }
      .padding(30)
      .background(Color.gray.opacity(0.8))
      .cornerRadius(16)
    }
    .transition(.opacity)
  }

  // Loading overlay
  private var loadingOverlay: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()

      VStack {
        ProgressView()
          .scaleEffect(1.5)

        Text("Processing Purchase...")
          .foregroundColor(.white)
          .padding(.top)
      }
      .padding(30)
      .background(Color.gray.opacity(0.8))
      .cornerRadius(16)
    }
  }

  // Purchase functions
  private func purchasePlatinumLootbox() {
    isPurchasing = true

    Task {
      let success = await iapManager.purchasePlatinumLootbox()

      await MainActor.run {
        isPurchasing = false

        if success {
          purchaseSuccessMessage =
            "Your Platinum Lootbox has been added to your tank! Tap it to open and discover new fish!"
          withAnimation {
            showPurchaseSuccess = true
          }
        }
      }
    }
  }

  private func purchaseSpeedBoost() {
    isPurchasing = true

    Task {
      let success = await iapManager.purchaseSpeedBoost()

      await MainActor.run {
        isPurchasing = false

        if success {
          purchaseSuccessMessage =
            "Speed Boost activated! Your commitments will progress 50% faster for the next 24 hours."
          withAnimation {
            showPurchaseSuccess = true
          }
        }
      }
    }
  }
}

#Preview {
  StoreView(isPresented: .constant(true))
}
