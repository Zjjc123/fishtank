//
//  GameObjects.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Game Objects
struct CollectedFish: Identifiable, Hashable, Codable {
  var id: UUID
  let fish: Fish
  var name: String
  let dateCaught: Date
  var isSwimming: Bool = false
  var isVisible: Bool = true
  let isShiny: Bool

  init(fish: Fish) {
    self.id = UUID()
    self.fish = fish
    self.name = fish.name
    self.dateCaught = Date()
    self.isShiny = Double.random(in: 0...1) < 0.01
  }
  
  init(id: UUID, fish: Fish, name: String, dateCaught: Date, isVisible: Bool = true, isShiny: Bool) {
    self.id = id
    self.fish = fish
    self.name = name
    self.dateCaught = dateCaught
    self.isVisible = isVisible
    self.isShiny = isShiny
  }

  // Custom Codable implementation to handle UUID properly
  enum CodingKeys: String, CodingKey {
    case id, fish, name, dateCaught, isSwimming, isVisible, isShiny
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    fish = try container.decode(Fish.self, forKey: .fish)
    name = try container.decode(String.self, forKey: .name)
    dateCaught = try container.decode(Date.self, forKey: .dateCaught)
    isSwimming = try container.decodeIfPresent(Bool.self, forKey: .isSwimming) ?? false
    isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
    isShiny = try container.decodeIfPresent(Bool.self, forKey: .isShiny) ?? false
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(fish, forKey: .fish)
    try container.encode(name, forKey: .name)
    try container.encode(dateCaught, forKey: .dateCaught)
    try container.encode(isSwimming, forKey: .isSwimming)
    try container.encode(isVisible, forKey: .isVisible)
    try container.encode(isShiny, forKey: .isShiny)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: CollectedFish, rhs: CollectedFish) -> Bool {
    lhs.id == rhs.id
  }

  // Convenience properties for backward compatibility
  var rarity: FishRarity { fish.rarity }
  var imageName: String { fish.imageName }
  var species: String { fish.name }
}

struct SwimmingFish: Identifiable {
  let id = UUID()
  var collectedFish: CollectedFish
  var x: CGFloat
  var y: CGFloat
  var size: CGFloat
  var speed: CGFloat
  var direction: CGFloat
  var verticalDirection: CGFloat = 0  // -1 for up, 0 for neutral, 1 for down
  var verticalSpeed: CGFloat = 0  // Current vertical speed
  var isStartled: Bool = false
  var startledTime: Date?
  var originalSpeed: CGFloat = 0

  var color: Color { collectedFish.fish.rarity.color }
  var rarity: FishRarity { collectedFish.fish.rarity }
  var imageName: String { collectedFish.fish.imageName }

  init(collectedFish: CollectedFish, in bounds: CGRect) {
    self.collectedFish = collectedFish
    self.x = CGFloat.random(in: 0...bounds.width)
    self.y = CGFloat.random(in: bounds.height * 0.2...bounds.height * 0.8)

    // Size is based on the fish's size property
    self.size = collectedFish.fish.size.displaySize
    self.speed = CGFloat.random(in: 0.1...0.4)
    self.originalSpeed = self.speed
    self.direction = CGFloat.random(in: -1...1)

    // Initialize vertical movement properties
    self.verticalDirection = CGFloat.random(in: -1...1)
    self.verticalSpeed = CGFloat.random(in: 0.05...0.15)
  }
}

struct CommitmentLootbox: Identifiable {
  let id = UUID()
  let type: LootboxType
  let x: CGFloat
  let y: CGFloat
}
