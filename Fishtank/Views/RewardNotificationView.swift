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
    VStack(spacing: 8) {
      Text(message)
        .font(.system(.title3, design: .rounded))
        .fontWeight(.medium)
        .foregroundColor(.white)
        .opacity(0.95)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    .background(notificationBackground)
    .padding(.horizontal, 25)
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.8)
    .blur(radius: isVisible ? 0 : 5)
    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
  }

  private var notificationBackground: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(.ultraThinMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.green.opacity(0.15))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.3), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
  }
}
