//
//  StatsDisplayView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct StatsDisplayView: View {
  let fishCount: Int
  let timeSpent: TimeInterval
  let giftBoxCount: Int
  let lootboxCount: Int

  var body: some View {
    HStack(spacing: 20) {
      StatItemView(value: "\(fishCount)", label: "Fish Collected", color: .white)
      StatItemView(value: formatTime(timeSpent), label: "Focus Time", color: .white)
      StatItemView(value: "\(giftBoxCount)", label: "Gift Boxes", color: .yellow)
      StatItemView(value: "\(lootboxCount)", label: "Lootboxes", color: .purple)
    }
    .padding(.bottom, 20)
  }

  private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}

struct StatItemView: View {
  let value: String
  let label: String
  let color: Color

  var body: some View {
    VStack {
      Text(value)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(color)
      Text(label)
        .font(.caption)
        .foregroundColor(.white.opacity(0.8))
    }
  }
}
