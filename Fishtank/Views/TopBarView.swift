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
  let onShareTapped: () -> Void
  let fishSpeciesCount: Int
  
  var body: some View {
    HStack {
      ClockDisplayView(currentTime: currentTime)
        .padding(.leading, 25)
        .padding(.top, 40)

      Spacer()
      
      // Share button
      Button(action: onShareTapped) {
        Image(systemName: "square.and.arrow.up")
          .font(.title2)
          .foregroundColor(.white)
          .opacity(0.6)
          .padding(12)
          .padding(.bottom, 3)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .contentShape(Circle()) // Ensure the entire circle is tappable
      }

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
          .contentShape(Circle()) // Ensure the entire circle is tappable
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
    onSettingsTapped: {},
    onShareTapped: {},
    fishSpeciesCount: 15
  )
  .background(Color.blue)
} 