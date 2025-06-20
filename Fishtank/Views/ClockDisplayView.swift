//
//  ClockDisplayView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct ClockDisplayView: View {
  let currentTime: Date

  var body: some View {
    VStack(spacing: 8) {
      Text(timeString(from: currentTime))
        .font(.custom("Gill Sans", size: 72, relativeTo: .largeTitle))
        .fontWeight(.regular)
        .foregroundColor(.white)
        .opacity(0.7)
        .shadow(color: .black.opacity(0.2), radius: 2)

      Text(dateString(from: currentTime))
        .font(.headline)
        .foregroundColor(.white.opacity(0.5))
        .shadow(color: .black.opacity(0.2), radius: 1)
    }
  }

  private func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }

  private func dateString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }
}
