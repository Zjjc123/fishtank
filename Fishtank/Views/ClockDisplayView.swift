//
//  ClockDisplayView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Combine
import SwiftUI

struct ClockDisplayView: View {
  let currentTime: Date
  @State private var displayTime: Date
  @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
  @State private var timerCancellable: Cancellable? = nil

  init(currentTime: Date) {
    self.currentTime = currentTime
    self._displayTime = State(initialValue: currentTime)
  }

  var body: some View {
    VStack(spacing: 8) {
      Text(timeString(from: displayTime))
        .font(.custom("Gill Sans", size: 72, relativeTo: .largeTitle))
        .fontWeight(.regular)
        .foregroundColor(.white)
        .opacity(0.7)
        .shadow(color: .black.opacity(0.2), radius: 2)

      Text(dateString(from: displayTime))
        .font(.headline)
        .foregroundColor(.white.opacity(0.5))
        .shadow(color: .black.opacity(0.2), radius: 1)
    }
    .allowsHitTesting(false)
    .onAppear {
      // Start the timer when the view appears
      self.timer = Timer.publish(every: 1, on: .main, in: .common)
      self.timerCancellable = self.timer.connect()
    }
    .onDisappear {
      // Cancel the timer when the view disappears
      self.timerCancellable?.cancel()
    }
    .onReceive(timer) { _ in
      // Update the display time every second
      self.displayTime = Date()
    }
    // Also update when the passed-in currentTime changes
    .onChange(of: currentTime) { newTime in
      self.displayTime = newTime
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
