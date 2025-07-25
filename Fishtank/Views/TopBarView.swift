//
//  TopBarView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct TopBarView: View {
  let isSyncing: Bool
  let onSettingsTapped: () -> Void
  let onStoreTapped: () -> Void
  let onShareTapped: () -> Void
  let fishSpeciesCount: Int

  @ObservedObject private var userPreferences = UserPreferences.shared

  private let buttonSize: CGFloat = 20
  private let buttonWidth: CGFloat = 40

  var body: some View {
    HStack {
      // Clock removed from here
      Spacer()

      // Right side: Buttons
      HStack(spacing: 15) {
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
          .background(Color.black.opacity(0.15))
          .cornerRadius(8)
        }

        // Store button
        Button(action: onStoreTapped) {
          Image(systemName: "cart")
            .font(.system(size: buttonSize))
            .foregroundColor(.white)
            .frame(width: buttonWidth, height: buttonWidth)
            .background(Color.black.opacity(0.15))
            .cornerRadius(8)
        }

        // Share button
        Button(action: onShareTapped) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: buttonSize))
            .foregroundColor(.white)
            .frame(width: buttonWidth, height: buttonWidth)
            .background(Color.black.opacity(0.15))
            .cornerRadius(8)
        }

        // Settings button
        Button(action: onSettingsTapped) {
          Image(systemName: "gear")
            .font(.system(size: buttonSize))
            .foregroundColor(.white)
            .frame(width: buttonWidth, height: buttonWidth)
            .background(Color.black.opacity(0.15))
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
  }
}

#Preview {
  ZStack {
    Color.blue
    TopBarView(
      isSyncing: false,
      onSettingsTapped: {},
      onStoreTapped: {},
      onShareTapped: {},
      fishSpeciesCount: 15
    )
  }
}
