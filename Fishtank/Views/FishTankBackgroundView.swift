//
//  FishTankBackgroundView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct FishTankBackgroundView: View {
  let currentTime: Date
  @ObservedObject private var userPreferences = UserPreferences.shared

  var body: some View {
    LinearGradient(
      colors: [backgroundColors.top, backgroundColors.bottom],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }

  // Get background colors based on user preference
  private var backgroundColors: (top: Color, bottom: Color) {
    // If the selected color requires purchase and backgrounds are not unlocked,
    // fall back to the default blue background
    if userPreferences.selectedBackgroundColor.requiresPurchase && !userPreferences.unlockedBackgrounds {
      return BackgroundColorOption.blue.colors
    }
    
    // Otherwise, use the selected background color
    return userPreferences.selectedBackgroundColor.colors
  }
}

#Preview {
  FishTankBackgroundView(currentTime: Date())
}
