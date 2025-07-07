//
//  BubbleView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct BubbleView: View {
  let bubble: Bubble

  var body: some View {
    ZStack {
      // Main bubble circle
      Circle()
        .fill(Color.white.opacity(bubble.opacity * 0.3))
        .frame(width: bubble.size, height: bubble.size)
        .overlay(
          Circle()
            .stroke(Color.white.opacity(bubble.opacity * 0.6), lineWidth: 1)
        )

      // Highlight reflection
      Circle()
        .fill(Color.white.opacity(bubble.opacity * 0.4))
        .frame(width: bubble.size * 0.3, height: bubble.size * 0.3)
        .offset(x: -bubble.size * 0.2, y: -bubble.size * 0.2)

      // Secondary reflection
      Circle()
        .fill(Color.white.opacity(bubble.opacity * 0.2))
        .frame(width: bubble.size * 0.15, height: bubble.size * 0.15)
        .offset(x: bubble.size * 0.15, y: -bubble.size * 0.25)
    }
    .blur(radius: 0.5)
  }
} 