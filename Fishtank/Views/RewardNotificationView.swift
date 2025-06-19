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
      VStack {
        Text(message)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding()
          .background(Color.green.opacity(0.8))
          .cornerRadius(10)
          .shadow(radius: 5)
      }
      .transition(.scale.combined(with: .opacity))
    }
  }
}
