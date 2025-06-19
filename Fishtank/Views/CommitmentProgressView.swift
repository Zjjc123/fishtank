//
//  CommitmentProgressView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct CommitmentProgressView: View {
  let commitment: FocusCommitment
  let progress: Double
  let timeRemaining: TimeInterval

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text("\(commitment.emoji) \(commitment.rawValue)")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
        Text(formatCommitmentTime(timeRemaining))
          .font(.headline)
          .foregroundColor(.yellow)
      }

      ProgressView(value: progress)
        .progressViewStyle(LinearProgressViewStyle(tint: .green))
        .scaleEffect(x: 1, y: 2, anchor: .center)
    }
    .padding(.horizontal, 30)
    .padding(.top, 20)
  }

  private func formatCommitmentTime(_ time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = (Int(time) % 3600) / 60
    let seconds = Int(time) % 60

    if hours > 0 {
      return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }
}
