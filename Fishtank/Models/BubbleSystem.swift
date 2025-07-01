//
//  BubbleSystem.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Bubble System
struct Bubble: Identifiable {
  let id = UUID()
  var x: CGFloat
  var y: CGFloat
  var size: CGFloat
  var speed: CGFloat
  var opacity: Double
  var wobble: CGFloat

  init(in bounds: CGRect) {
    self.x = CGFloat.random(in: 0...bounds.width)
    // Random start position - some start below screen, some start within screen
    let startY = CGFloat.random(in: bounds.height * 0.5...bounds.height + 50)
    self.y = startY
    self.size = CGFloat.random(in: 4...15)  // Smaller size range
    self.speed = CGFloat.random(in: 0.3...1.0)  // Slightly slower
    self.opacity = Double.random(in: 0.2...0.5)  // Lower opacity
    self.wobble = CGFloat.random(in: -0.3...0.3)  // Less wobble
  }
}

@MainActor
final class BubbleManager: ObservableObject {
  static let shared = BubbleManager(bounds: UIScreen.main.bounds)
  
  @Published var bubbles: [Bubble] = []
  private let bounds: CGRect
  private let maxBubbles = 20
  private let bubbleSpawnChance = 0.1 // 10% chance to spawn a new bubble each animation frame
  
  init(bounds: CGRect) {
    self.bounds = bounds
    spawnInitialBubbles()
  }

  private func spawnInitialBubbles() {
    for _ in 0..<maxBubbles {
      bubbles.append(Bubble(in: bounds))
    }
  }

  func animateBubbles() {
    for i in bubbles.indices {
      // Move bubble upward
      bubbles[i].y -= bubbles[i].speed

      // Add slight horizontal wobble
      bubbles[i].x += bubbles[i].wobble

      // Reset bubble when it goes off screen with random delay
      if bubbles[i].y < -50 {
        // Add some randomness to when bubbles respawn
        if Double.random(in: 0...1) < 0.1 {  // 10% chance to respawn immediately
          bubbles[i] = Bubble(in: bounds)
        } else {
          // Otherwise, keep it off screen for a bit
          bubbles[i].y = bounds.height + CGFloat.random(in: 0...100)
        }
      }

      // Keep bubbles within horizontal bounds
      if bubbles[i].x < 0 {
        bubbles[i].x = 0
        bubbles[i].wobble = abs(bubbles[i].wobble)
      } else if bubbles[i].x > bounds.width {
        bubbles[i].x = bounds.width
        bubbles[i].wobble = -abs(bubbles[i].wobble)
      }
    }
  }
}
