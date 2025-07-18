//
//  MainView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct MainView: View {
  @StateObject private var supabaseManager = SupabaseManager.shared
  @StateObject private var fishTankManager = FishTankManager.shared
  @StateObject private var bubbleManager = BubbleManager.shared
  @AppStorage("shouldShowAuthView") private var shouldShowAuthView = false
  @State private var forceUpdate: Bool = false

  var body: some View {
    Group {
      if ((supabaseManager.isAuthenticated && !supabaseManager.needsUsernameSetup) || supabaseManager.isGuest) && !shouldShowAuthView {
        ZStack(alignment: .top) {
          ContentView()
            .environmentObject(supabaseManager)
            .onAppear {
              // Force landscape orientation when authenticated or guest
              setOrientation(to: .landscape)
            }
        }
      } else {
        AuthView()
          .onDisappear {
            // Only reset the flag when auth view disappears if user is authenticated
            if supabaseManager.isAuthenticated || supabaseManager.isGuest {
              shouldShowAuthView = false
            }

            // Only set landscape orientation if user is authenticated or guest
            // and doesn't need username setup (or is guest)
            if (supabaseManager.isAuthenticated && !supabaseManager.needsUsernameSetup) || supabaseManager.isGuest {
              setOrientation(to: .landscape)
            }
          }
          .onAppear {
            // Force portrait orientation for auth view
            setOrientation(to: .portrait)
          }
      }
    }
    .onAppear {
      // Check authentication status when app appears
      Task {
        await supabaseManager.checkCurrentUser()
      }

      // Listen for authentication state changes
      setupAuthStateObserver()
    }
    // Force view update when authentication state changes
    .id(forceUpdate)
  }

  // Setup observer for authentication state changes
  private func setupAuthStateObserver() {
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name("SupabaseAuthStateChanged"),
      object: nil,
      queue: .main
    ) { notification in
      // Check if user is in guest mode
      if let isGuest = notification.userInfo?["isGuest"] as? Bool, isGuest {
        // If in guest mode, we should show ContentView
        self.shouldShowAuthView = false
      }
      // Check if user needs username setup
      else if let needsUsernameSetup = notification.userInfo?["needsUsernameSetup"] as? Bool, 
         needsUsernameSetup {
        // If username setup is needed, make sure we show the AuthView
        self.shouldShowAuthView = true
      } else if let isAuthenticated = notification.userInfo?["isAuthenticated"] as? Bool,
                !isAuthenticated {
        // If user is not authenticated, make sure we show the AuthView
        self.shouldShowAuthView = true
      }
      
      // Force view to update when auth state changes
      self.forceUpdate.toggle()
    }
  }

  // Helper function to set orientation with proper delay
  private func setOrientation(to orientation: UIInterfaceOrientationMask) {
    // Set app orientation mask first
    AppDelegate.orientationLock = orientation

    // Get the windowScene
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return
    }

    if orientation == .landscape {
      // Request landscape orientation using the recommended API
      let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
        interfaceOrientations: .landscapeRight)
      windowScene.requestGeometryUpdate(geometryPreferences)

      // Force UI update after a slight delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        if #available(iOS 16.0, *) {
          UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .forEach { $0.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
        } else {
          UIViewController.attemptRotationToDeviceOrientation()
        }
      }
    } else {
      // Request portrait orientation using the recommended API
      let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
        interfaceOrientations: .portrait)
      windowScene.requestGeometryUpdate(geometryPreferences)

      // Force UI update after a slight delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        if #available(iOS 16.0, *) {
          UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .forEach { $0.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
        } else {
          UIViewController.attemptRotationToDeviceOrientation()
        }
      }
    }
  }
}

#Preview {
  MainView()
}
