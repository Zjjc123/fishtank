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

        VStack(spacing: 0) {
          VStack(spacing: 8) {
            Text("Store")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.white)

            Text("Enhance your experience")
              .font(.caption)
              .foregroundColor(.white.opacity(0.8))
              .padding(.bottom, 2)

            storeItemsView
              .frame(maxWidth: 600)  // Slightly narrower width constraint
          }
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, alignment: .center)  // Center the content
        }
        .frame(maxWidth: .infinity)

        // Close button
        VStack {
          HStack {
            Spacer()
            Button(action: {
              isPresented = false
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(.white.opacity(0.8))
                .padding(12)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .padding(.top, 20)
            .padding(.trailing, 8)
          }

          Spacer()
        }
      }
      .onAppear {
        Task {
          await iapManager.ensureProductsLoaded()
        }
      }
      .navigationBarHidden(true)
    }
  }

  // Combined store items view
  private var storeItemsView: some View {
    VStack(spacing: 8) {
      // Platinum lootbox card
      storeItemCard(
        title: "Platinum Lootbox",
        description: "Highest chance for rare fish",
        icon: "🎁",
        price: iapManager.getPlatinumLootboxPrice(),
        action: {
          purchasePlatinumLootbox()
        }
      )

      // 10x Platinum lootboxes card
      storeItemCard(
        title: "10x Platinum Lootboxes",
        description: "Bundle at discounted price",
        customIcon: {
          ZStack {
            Text("🎁")
              .font(.system(size: 12))
              .offset(x: -8, y: -4)

            Text("🎁")
              .font(.system(size: 12))
              .offset(x: 0, y: 0)

            Text("🎁")
              .font(.system(size: 12))
              .offset(x: 9, y: 5)
          }
        },
        price: iapManager.getPlatinumLootbox10Price(),
        action: {
          purchase10PlatinumLootboxes()
        }
      )

      // Speed boost card
      storeItemCard(
        title: "Speed Boost (24h)",
        description: userPreferences.hasSpeedBoost
          ? "Active: \(userPreferences.formattedSpeedBoostTimeRemaining())"
          : "Complete commitments 50% faster",
        icon: "⚡️",
        price: iapManager.getSpeedBoostPrice(),
        action: {
          purchaseSpeedBoost()
        },
        disabled: userPreferences.hasSpeedBoost
      )
    }
    .padding(.vertical, 8)
  }

  // Reusable store item card with icon
  private func storeItemCard(
    title: String, description: String, icon: String,
    price: String, action: @escaping () -> Void, disabled: Bool = false
  ) -> some View {
    storeItemCardBase(
      title: title,
      description: description,
      iconView: {
        Text(icon)
          .font(.system(size: 20))
      },
      price: price,
      action: action,
      disabled: disabled
    )
  }

  // Reusable store item card with custom icon view
  private func storeItemCard(
    title: String, description: String, customIcon: @escaping () -> some View,
    price: String, action: @escaping () -> Void, disabled: Bool = false
  ) -> some View {
    storeItemCardBase(
      title: title,
      description: description,
      iconView: customIcon,
      price: price,
      action: action,
      disabled: disabled
    )
  }

  // Base store item card implementation
  private func storeItemCardBase<IconContent: View>(
    title: String, description: String, iconView: @escaping () -> IconContent,
    price: String, action: @escaping () -> Void, disabled: Bool = false
  ) -> some View {
    VStack {
      HStack(spacing: 8) {  // Reduced spacing between elements
        // Icon container
        ZStack {
          Circle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 38, height: 38)  // Slightly smaller icon

          iconView()
        }
        .frame(width: 38, height: 38)  // Match the circle size
        .padding(.leading, 2)  // Reduced left padding

        // Text content
        VStack(alignment: .leading, spacing: 1) {
          Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)

          Text(description)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
        .padding(.leading, 2)  // Add a bit of padding

        Spacer()

        // Purchase button
        Button(action: action) {
          ZStack {
            if disabled {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.7))
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            } else {
              RoundedRectangle(cornerRadius: 8)
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                  )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            }

            if iapManager.isPurchasing {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            } else {
              Text(price)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .font(.footnote)
            }
          }
          .frame(width: 58, height: 28)  // Slightly narrower button
        }
        .disabled(disabled || iapManager.isPurchasing)
        .padding(.trailing, 2)  // Reduced right padding
      }
      .padding(6)  // Reduced padding around the HStack
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.white.opacity(0.15))
          .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
      )
      .cornerRadius(10)
    }
  }

  // Purchase functions
  private func purchasePlatinumLootbox() {
    Task {
      await iapManager.purchasePlatinumLootbox()
    }
  }

  private func purchase10PlatinumLootboxes() {
    Task {
      await iapManager.purchasePlatinumLootbox10()
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
