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
        HStack(spacing: 6) {
          Image(systemName: commitment.iconName)
            .font(.headline)
            .foregroundColor(.white)
            .opacity(0.8)
          Text(commitment.rawValue)
            .font(.headline)
            .foregroundColor(.white)
            .opacity(0.8)
        }
        Spacer()
        Text(formatCommitmentTime(timeRemaining))
          .font(.headline)
          .foregroundColor(.yellow)
          .opacity(0.9)
      }

      ProgressView(value: progress)
        .progressViewStyle(LinearProgressViewStyle(tint: .green.opacity(0.7)))
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
