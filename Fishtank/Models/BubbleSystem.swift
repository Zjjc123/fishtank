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
    // Ensure we're using landscape bounds
    let landscapeBounds = bounds.width > bounds.height ? bounds : 
                          CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
    
    self.x = CGFloat.random(in: 0...landscapeBounds.width)
    // Random start position - some start below screen, some start within screen
    let startY = CGFloat.random(in: landscapeBounds.height * 0.5...landscapeBounds.height + 50)
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
  private var bounds: CGRect
  private let maxBubbles = 20
  private let bubbleSpawnChance = 0.1 // 10% chance to spawn a new bubble each animation frame
  
  init(bounds: CGRect) {
    // Always use landscape bounds (width > height)
    let screenBounds = bounds
    self.bounds = screenBounds.width > screenBounds.height ? screenBounds : 
                  CGRect(x: 0, y: 0, width: screenBounds.height, height: screenBounds.width)
    spawnInitialBubbles()
  }

  // Update bounds when orientation changes
  func updateBounds(newBounds: CGRect) {
    // Always use landscape bounds (width > height)
    let landscapeBounds = newBounds.width > newBounds.height ? newBounds : 
                          CGRect(x: 0, y: 0, width: newBounds.height, height: newBounds.width)
    
    let widthRatio = landscapeBounds.width / bounds.width
    let heightRatio = landscapeBounds.height / bounds.height

    // Update bubble positions based on the new bounds
    for i in bubbles.indices {
      // Scale positions proportionally to new bounds
      bubbles[i].x *= widthRatio
      bubbles[i].y *= heightRatio

      // Ensure bubbles stay within bounds
      bubbles[i].x = max(0, min(landscapeBounds.width, bubbles[i].x))
    }

    // Update the bounds
    self.bounds = landscapeBounds
  }

  private func spawnInitialBubbles() {
    for _ in 0..<maxBubbles {
      bubbles.append(Bubble(in: bounds))
    }
  }

  func animateBubbles() {
    // Ensure we're using landscape bounds
    let landscapeBounds = bounds.width > bounds.height ? bounds : 
                          CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
    
    for i in bubbles.indices {
      // Move bubble upward
      bubbles[i].y -= bubbles[i].speed

      // Add slight horizontal wobble
      bubbles[i].x += bubbles[i].wobble

      // Reset bubble when it goes off screen with random delay
      if bubbles[i].y < -50 {
        // Add some randomness to when bubbles respawn
        if Double.random(in: 0...1) < 0.1 {  // 10% chance to respawn immediately
          bubbles[i] = Bubble(in: landscapeBounds)
        } else {
          // Otherwise, keep it off screen for a bit
          bubbles[i].y = landscapeBounds.height + CGFloat.random(in: 0...100)
        }
      }

      // Keep bubbles within horizontal bounds
      if bubbles[i].x < 0 {
        bubbles[i].x = 0
        bubbles[i].wobble = abs(bubbles[i].wobble)
      } else if bubbles[i].x > landscapeBounds.width {
        bubbles[i].x = landscapeBounds.width
        bubbles[i].wobble = -abs(bubbles[i].wobble)
      }
    }
  }
}
