//
//  TopBarView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct TopBarView: View {
  let currentTime: Date
  let isSyncing: Bool
  let onSettingsTapped: () -> Void
  let onStoreTapped: () -> Void
  let onShareTapped: () -> Void
  let fishSpeciesCount: Int
  
  @ObservedObject private var userPreferences = UserPreferences.shared
  
  var body: some View {
    HStack {
      // Left side: Clock
      ClockDisplayView(currentTime: currentTime)
        .padding(.leading, 15)
      
      Spacer()
      
      // Center: Fish count
      HStack(spacing: 4) {
        Image(systemName: "fish")
          .foregroundColor(.white)
        Text("\(fishSpeciesCount)")
          .foregroundColor(.white)
          .font(.system(size: 16, weight: .bold))
      }
      .padding(8)
      .background(Color.black.opacity(0.3))
      .cornerRadius(8)
      
      // Speed boost indicator if active
      if userPreferences.hasSpeedBoost {
        HStack(spacing: 4) {
          Image(systemName: "bolt.fill")
            .foregroundColor(.yellow)
          Text(userPreferences.formattedSpeedBoostTimeRemaining())
            .foregroundColor(.white)
            .font(.system(size: 14))
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
      }
      
      Spacer()
      
      // Right side: Buttons
      HStack(spacing: 15) {
        // Store button
        Button(action: onStoreTapped) {
          Image(systemName: "cart")
            .font(.system(size: 20))
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
        
        // Share button
        Button(action: onShareTapped) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 20))
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
        
        // Settings button
        Button(action: onSettingsTapped) {
          Image(systemName: "gear")
            .font(.system(size: 20))
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .overlay(
              Group {
                if isSyncing {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.7)
                }
              }
            )
        }
      }
      .padding(.trailing, 15)
    }
    .frame(height: 50)
    .background(Color.black.opacity(0.2))
  }
}

#Preview {
  ZStack {
    Color.blue
    TopBarView(
      currentTime: Date(),
      isSyncing: false,
      onSettingsTapped: {},
      onStoreTapped: {},
      onShareTapped: {},
      fishSpeciesCount: 15
    )
  }
}
