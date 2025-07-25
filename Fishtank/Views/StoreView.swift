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

      // Speed boost card
      storeItemCard(
        title: "Speed Boost (24 Hours)",
        description: userPreferences.hasSpeedBoost
          ? "Already active: \(userPreferences.formattedSpeedBoostTimeRemaining())"
          : "Complete commitments 50% faster for 24 hours!",
        icon: "⚡️",
        price: iapManager.getSpeedBoostPrice(),
        action: {
          purchaseSpeedBoost()
        },
        disabled: userPreferences.hasSpeedBoost
      )
    }
    .padding()
  }

  // Reusable store item card
  private func storeItemCard(
    title: String, description: String, icon: String, price: String, action: @escaping () -> Void,
    disabled: Bool = false
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
            .background(disabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(disabled || iapManager.isPurchasing)
      }
      .padding()
      .background(Color.white.opacity(0.1))
      .cornerRadius(12)
    }
  }

  // Purchase functions
  private func purchasePlatinumLootbox() {
    Task {
      await iapManager.purchasePlatinumLootbox()
    }
  }

  private func purchaseSpeedBoost() {
    Task {
      await iapManager.purchaseSpeedBoost()
    }
  }
}

#Preview {
  StoreView(isPresented: .constant(true))
}
