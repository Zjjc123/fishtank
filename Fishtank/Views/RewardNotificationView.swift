//
//  RewardNotificationView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct RewardNotificationView: View {
  let message: String
  let isVisible: Bool

  var body: some View {
    if isVisible {
      VStack(spacing: 8) {
        Text(message)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .opacity(0.9)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
      }
      .background(notificationBackground)
      .padding(.horizontal, 20)
      .transition(.scale.combined(with: .opacity))
    }
  }

  private var notificationBackground: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(.regularMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.green.opacity(0.3))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
      )
      .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
      .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
  }
}
