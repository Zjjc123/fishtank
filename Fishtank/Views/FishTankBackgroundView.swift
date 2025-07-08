//
//  FishTankBackgroundView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct FishTankBackgroundView: View {
  let currentTime: Date
  
  var body: some View {
    LinearGradient(
      colors: [timeBasedBackground.topColor, timeBasedBackground.bottomColor],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
  
  // Time-based background colors
  private var timeBasedBackground: (topColor: Color, bottomColor: Color) {
    let hour = Calendar.current.component(.hour, from: currentTime)
    return getBackgroundColors(for: hour)
  }

  private func getBackgroundColors(for hour: Int) -> (topColor: Color, bottomColor: Color) {
    switch hour {
    case 5..<7:  // Early morning (5-7 AM) - Dawn
      return (Color.orange.opacity(0.2), Color.pink.opacity(0.15))
    case 7..<10:  // Morning (7-10 AM) - Bright morning
      return (Color.cyan.opacity(0.25), Color.blue.opacity(0.3))
    case 10..<16:  // Day (10 AM-4 PM) - Bright day
      return (Color.cyan.opacity(0.6), Color.blue.opacity(0.7))
    case 16..<19:  // Afternoon (4-7 PM) - Golden hour
      return (Color.orange.opacity(0.5), Color.yellow.opacity(0.4))
    case 19..<21:  // Evening (7-9 PM) - Sunset
      return (Color.pink.opacity(0.4), Color.orange.opacity(0.5))
    case 21..<23:  // Night (9-11 PM) - Early night
      return (Color.purple.opacity(0.4), Color.blue.opacity(0.6))
    case 23...23, 0..<5:  // Late night (11 PM-5 AM) - Deep night
      return (Color.black.opacity(0.25), Color.purple.opacity(0.3))
    default:
      return (Color.cyan.opacity(0.2), Color.blue.opacity(0.25))
    }
  }
}

#Preview {
  FishTankBackgroundView(currentTime: Date())
} 