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
  
  var body: some View {
    HStack {
      ClockDisplayView(currentTime: currentTime)
        .padding(.leading, 25)
        .padding(.top, 40)

      Spacer()

      // Sync indicator
      if isSyncing {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .white))
          .scaleEffect(0.8)
          .opacity(0.6)
          .padding(.trailing, 10)
      }

      Button(action: onSettingsTapped) {
        Image(systemName: "gearshape.fill")
          .font(.title2)
          .foregroundColor(.white)
          .opacity(0.6)
          .padding(12)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
      }
      .padding(.trailing, 25)
    }
    .padding(.top, 20)
  }
}

#Preview {
  TopBarView(
    currentTime: Date(),
    isSyncing: false,
    onSettingsTapped: {}
  )
  .background(Color.blue)
} 