//
//  SettingsView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import StoreKit
import Supabase
import SwiftUI

struct SettingsView: View {
  @Binding var isPresented: Bool
  let statsManager: GameStateManager
  let fishTankManager: FishTankManager
  @StateObject private var supabaseManager = SupabaseManager.shared
  @ObservedObject private var userPreferences = UserPreferences.shared
  @ObservedObject private var iapManager = InAppPurchaseManager.shared
  @State private var showingSignOutAlert = false
  @State private var isOnline = true
  @State private var showSignUpAlert = false
  @State private var showPurchaseAlert = false
  @State private var selectedColorForPurchase: BackgroundColorOption?
  @AppStorage("shouldShowAuthView") private var shouldShowAuthView = false

  private func signOut() async {
    await supabaseManager.signOut()
  }

  private func checkConnection() {
    Task {
      // Simple network check by trying to make a connection
      do {
        let url = URL(string: "https://www.apple.com")!
        let (_, response) = try await URLSession.shared.data(from: url)

        await MainActor.run {
          isOnline = (response as? HTTPURLResponse)?.statusCode == 200
        }
      } catch {
        await MainActor.run {
          isOnline = false
        }
      }
    }
  }

  var body: some View {
    ZStack {
      // Background overlay
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      // Main content
      VStack(spacing: 16) {
        headerView

        // Settings Options
        ScrollView {
          connectionStatusView
          storageInfoView
          backgroundColorSelectionView
          restorePurchasesButton
          accountButtonsView
        }
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
          )
      )
      .padding(.horizontal, 100)
      .onAppear {
        checkConnection()
        Task {
          await iapManager.ensureProductsLoaded()
        }
      }
    }
    .alert("Create Account", isPresented: $showSignUpAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Continue", role: .none) {
        // Exit guest mode and show auth view with sign up mode
        Task {
          await MainActor.run {
            // Set flag to show auth view
            shouldShowAuthView = true
            // Close settings view
            isPresented = false
            // Exit guest mode
            supabaseManager.exitGuestMode()
          }
        }
      }
    } message: {
      Text(
        "Would you like to create an account? Your fish collection will be saved to your new account."
      )
    }

    // Sign Out Alert
    .alert("Sign Out", isPresented: $showingSignOutAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Sign Out", role: .destructive) {
        Task {
          await signOut()
        }
      }
    } message: {
      Text(
        "Are you sure you want to sign out? Your fish collection will remain saved to your account."
      )
    }

    // Purchase Alert
    .alert("Unlock All Backgrounds", isPresented: $showPurchaseAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Purchase", role: .none) {
        Task {
          let success = await iapManager.purchaseBackgrounds()
          if success {
            // If successful, the transaction listener will update userPreferences.unlockedBackgrounds
            // and the UI will update automatically
          }
        }
      }
    } message: {
      Text("Unlock all background colors for \(iapManager.getBackgroundsPrice())?")
    }
  }

  // MARK: - Extracted Views

  private var headerView: some View {
    HStack(spacing: 8) {
      Image(systemName: "gearshape.fill")
        .font(.title3)
        .foregroundColor(.white.opacity(0.9))

      Text("Settings")
        .font(.system(.headline, design: .rounded))
        .fontWeight(.semibold)
        .foregroundColor(.white)
    }
    .padding(.top, 6)
  }

  private var connectionStatusView: some View {
    HStack(spacing: 8) {
      Image(systemName: isOnline ? "wifi" : "wifi.slash")
        .font(.title3)
        .foregroundColor(isOnline ? .green.opacity(0.9) : .red.opacity(0.9))

      Text("Connection Status")
        .font(.system(.subheadline, design: .rounded))
        .foregroundColor(.white.opacity(0.8))

      Spacer()

      Text(isOnline ? "Online" : "Offline")
        .font(.system(.headline, design: .rounded))
        .fontWeight(.semibold)
        .foregroundColor(isOnline ? .green : .red)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    )
  }

  private var storageInfoView: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "externaldrive.fill")
          .font(.title3)
          .foregroundColor(.blue.opacity(0.9))

        Text("Storage Information")
          .font(.system(.subheadline, design: .rounded))
          .foregroundColor(.white.opacity(0.8))

        Spacer()

        Text("\(statsManager.fishCount)")
          .font(.system(.headline, design: .rounded))
          .fontWeight(.semibold)
          .foregroundColor(.blue)
      }

      storageInfoDetailsView
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    )
  }

  private var storageInfoDetailsView: some View {
    HStack(spacing: 6) {
      Image(systemName: "info.circle.fill")
        .font(.caption)
        .foregroundColor(.blue.opacity(0.8))

      storageStatusText
    }
  }

  private var storageStatusText: some View {
    Group {
      if supabaseManager.isAuthenticated && isOnline {
        Text("Fish are synced to your account")
          .font(.system(.caption, design: .rounded))
          .foregroundColor(.blue.opacity(0.8))
          .multilineTextAlignment(.leading)
      } else if supabaseManager.isAuthenticated && !isOnline {
        Text("Fish are saved locally (offline mode, will sync when online)")
          .font(.system(.caption, design: .rounded))
          .foregroundColor(.orange.opacity(0.8))
          .multilineTextAlignment(.leading)
      } else if supabaseManager.isGuest {
        Text("Fish are saved locally on your device (guest mode)")
          .font(.system(.caption, design: .rounded))
          .foregroundColor(.yellow.opacity(0.8))
          .multilineTextAlignment(.leading)
      } else {
        Text("Fish are saved locally on your device")
          .font(.system(.caption, design: .rounded))
          .foregroundColor(.blue.opacity(0.8))
          .multilineTextAlignment(.leading)
      }
    }
  }

  private var backgroundColorSelectionView: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "paintpalette.fill")
          .font(.title3)
          .foregroundColor(.purple.opacity(0.9))

        Text("Background Color")
          .font(.system(.subheadline, design: .rounded))
          .foregroundColor(.white.opacity(0.8))

        Spacer()

        if !userPreferences.unlockedBackgrounds {
          Button(action: {
            showPurchaseAlert = true
          }) {
            HStack(spacing: 4) {
              Image(systemName: "lock.open")
                .font(.caption)
              Text("Unlock All")
                .font(.system(.caption, design: .rounded))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              Capsule()
                .fill(Color.purple.opacity(0.7))
            )
            .foregroundColor(.white)
          }
        }
      }

      colorSelectionGrid
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    )
    .padding(.vertical, 8)
  }

  private var colorSelectionGrid: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
      ForEach(BackgroundColorOption.allCases) { colorOption in
        colorSelectionButton(for: colorOption)
      }
    }
    .padding(.vertical, 8)
  }

  private func colorSelectionButton(for colorOption: BackgroundColorOption) -> some View {
    Button(action: {
      if colorOption.requiresPurchase && !userPreferences.unlockedBackgrounds {
        // Show purchase dialog
        selectedColorForPurchase = colorOption
        showPurchaseAlert = true
      } else {
        // Select the color
        userPreferences.selectedBackgroundColor = colorOption
      }
    }) {
      VStack {
        ZStack {
          colorCircle(for: colorOption)

          if colorOption == userPreferences.selectedBackgroundColor {
            Circle()
              .stroke(Color.white, lineWidth: 3)
              .frame(width: 46, height: 46)
          }

          // Show lock icon for locked colors
          if colorOption.requiresPurchase && !userPreferences.unlockedBackgrounds {
            Circle()
              .fill(Color.black.opacity(0.5))
              .frame(width: 40, height: 40)

            Image(systemName: "lock.fill")
              .font(.system(size: 16))
              .foregroundColor(.white)
          }
        }

        Text(colorOption.rawValue)
          .font(.system(.caption, design: .rounded))
          .foregroundColor(.white.opacity(0.8))
      }
    }
    .buttonStyle(PlainButtonStyle())
  }

  private func colorCircle(for colorOption: BackgroundColorOption) -> some View {
    LinearGradient(
      colors: [colorOption.colors.top, colorOption.colors.bottom],
      startPoint: .top,
      endPoint: .bottom
    )
    .clipShape(Circle())
    .frame(width: 40, height: 40)
  }

  private var restorePurchasesButton: some View {
    Button(action: {
      Task {
        await iapManager.restorePurchases()
      }
    }) {
      HStack(spacing: 8) {
        Image(systemName: "arrow.clockwise")
          .font(.subheadline)
        Text("Restore Purchases")
          .font(.system(.subheadline, design: .rounded))
      }
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 40)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.purple.opacity(0.7))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.purple.opacity(0.3), lineWidth: 1)
          )
      )
    }
    .padding(.vertical, 8)
  }

  private var accountButtonsView: some View {
    VStack(spacing: 8) {
      guestModeView
      accountInfoView
      signOutButton
      closeButton
    }
  }

  private var guestModeView: some View {
    Group {
      if supabaseManager.isGuest {
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
              .font(.title3)
              .foregroundColor(.yellow.opacity(0.9))

            Text("Guest Mode")
              .font(.system(.subheadline, design: .rounded))
              .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text("Create an account to save your fish online")
              .font(.system(.caption, design: .rounded))
              .foregroundColor(.yellow.opacity(0.8))
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(.ultraThinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
              )
          )

          Button(action: {
            showSignUpAlert = true
          }) {
            HStack(spacing: 8) {
              Image(systemName: "person.badge.plus")
                .font(.subheadline)
              Text("Sign Up")
                .font(.system(.subheadline, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.7))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            )
          }
        }
      }
    }
  }

  private var accountInfoView: some View {
    Group {
      if supabaseManager.isAuthenticated && !supabaseManager.isGuest {
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
              .font(.title3)
              .foregroundColor(.green.opacity(0.9))

            Text("Account")
              .font(.system(.subheadline, design: .rounded))
              .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(supabaseManager.currentUser?.email ?? "")
              .font(.system(.caption, design: .rounded))
              .foregroundColor(.green.opacity(0.8))
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(.ultraThinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.white.opacity(0.2), lineWidth: 1)
              )
          )
        }
      }
    }
  }

  private var signOutButton: some View {
    Group {
      if supabaseManager.isAuthenticated && !supabaseManager.isGuest {
        Button(action: {
          showingSignOutAlert = true
        }) {
          HStack(spacing: 8) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
              .font(.subheadline)
            Text("Sign Out")
              .font(.system(.subheadline, design: .rounded))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 40)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.red.opacity(0.7))
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.red.opacity(0.3), lineWidth: 1)
              )
          )
        }
      }
    }
  }

  private var closeButton: some View {
    Button(action: {
      isPresented = false
    }) {
      HStack(spacing: 6) {
        Image(systemName: "xmark.circle")
          .font(.subheadline)
        Text("Close")
          .font(.system(.subheadline, design: .rounded))
      }
      .foregroundColor(.white.opacity(0.7))
      .frame(maxWidth: .infinity)
      .frame(height: 40)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.white.opacity(0.2), lineWidth: 1)
          )
      )
    }
  }
}
