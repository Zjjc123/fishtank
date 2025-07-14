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
      if (supabaseManager.isAuthenticated || supabaseManager.isGuest) && !shouldShowAuthView {
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
            // Reset the flag when auth view disappears
            shouldShowAuthView = false

            // Only set landscape orientation if user is authenticated or guest
            if supabaseManager.isAuthenticated || supabaseManager.isGuest {
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
        UIViewController.attemptRotationToDeviceOrientation()
      }
    } else {
      // Request portrait orientation using the recommended API
      let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
        interfaceOrientations: .portrait)
      windowScene.requestGeometryUpdate(geometryPreferences)

      // Force UI update after a slight delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        UIViewController.attemptRotationToDeviceOrientation()
      }
    }
  }
}

#Preview {
  MainView()
}
