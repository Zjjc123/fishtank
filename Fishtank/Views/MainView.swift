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
          if supabaseManager.isGuest {
            HStack {
              Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundColor(.yellow)
              Text("You are playing as a guest. Your progress is saved locally.")
                .font(.caption)
                .foregroundColor(.yellow)
              Spacer()
            }
            .padding(10)
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
            .padding([.top, .horizontal], 16)
          }
        }
      } else {
        AuthView()
          .onDisappear {
            // Reset the flag when auth view disappears
            shouldShowAuthView = false
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
    if orientation == .landscape {
      // Set device orientation
      UIDevice.current.setValue(
        UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
      // Set app orientation mask
      AppDelegate.orientationLock = .landscape

      // Force UI update after a slight delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        // Additional rotation force if needed
        UIViewController.attemptRotationToDeviceOrientation()
      }
    } else {
      // Set device orientation
      UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
      // Set app orientation mask
      AppDelegate.orientationLock = .portrait
    }
  }
}

#Preview {
  MainView()
}
