//
//  GameObjects.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Game Objects
struct CollectedFish: Identifiable, Hashable, Codable {
  let id: UUID
  let rarity: FishRarity
  let imageName: String
  let species: String
  var name: String
  let dateCaught: Date
  var isSwimming: Bool = false
  var isVisible: Bool = true

  init(rarity: FishRarity) {
    self.id = UUID()
    self.rarity = rarity
    let fishOption = rarity.fishOptions.randomElement()!
    self.imageName = fishOption.imageName
    self.species = fishOption.name
    self.name = fishOption.name // Default name is the species name
    self.dateCaught = Date()
  }

  // Custom Codable implementation to handle UUID properly
  enum CodingKeys: String, CodingKey {
    case id, rarity, imageName, species, name, dateCaught, isSwimming, isVisible
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    rarity = try container.decode(FishRarity.self, forKey: .rarity)
    imageName = try container.decode(String.self, forKey: .imageName)
    
    // Handle backward compatibility - if species doesn't exist, use name for both
    if container.contains(.species) {
      species = try container.decode(String.self, forKey: .species)
    } else {
      species = try container.decode(String.self, forKey: .name)
    }
    
    name = try container.decode(String.self, forKey: .name)
    dateCaught = try container.decode(Date.self, forKey: .dateCaught)
    isSwimming = try container.decodeIfPresent(Bool.self, forKey: .isSwimming) ?? false
    isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(rarity, forKey: .rarity)
    try container.encode(imageName, forKey: .imageName)
    try container.encode(species, forKey: .species)
    try container.encode(name, forKey: .name)
    try container.encode(dateCaught, forKey: .dateCaught)
    try container.encode(isSwimming, forKey: .isSwimming)
    try container.encode(isVisible, forKey: .isVisible)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: CollectedFish, rhs: CollectedFish) -> Bool {
    lhs.id == rhs.id
  }
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

  var color: Color { collectedFish.rarity.color }
  var rarity: FishRarity { collectedFish.rarity }
  var imageName: String { collectedFish.imageName }

  init(collectedFish: CollectedFish, in bounds: CGRect) {
    self.collectedFish = collectedFish
    self.x = CGFloat.random(in: 0...bounds.width)
    self.y = CGFloat.random(in: bounds.height * 0.2...bounds.height * 0.8)
    
    // Size scales with rarity - rarer fish are larger
    let baseSize: CGFloat
    let sizeVariation: CGFloat = 5.0 // Random variation within rarity
    
    switch collectedFish.rarity {
    case .common:
      baseSize = 25.0
    case .uncommon:
      baseSize = 35.0
    case .rare:
      baseSize = 45.0
    case .epic:
      baseSize = 55.0
    case .legendary:
      baseSize = 80.0
    }
    
    self.size = baseSize + CGFloat.random(in: -sizeVariation...sizeVariation)
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
