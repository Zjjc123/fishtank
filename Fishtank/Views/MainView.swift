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

  var body: some View {
    Group {
      if supabaseManager.isAuthenticated {
        ContentView()
          .environmentObject(supabaseManager)
          .onAppear {
            // Force landscape orientation when authenticated
            setOrientation(to: .landscape)
            
            // No need to update bounds on orientation change anymore
            // We're always using landscape bounds
          }
          // Remove the willEnterForeground notification handler
      } else {
        AuthView()
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
