//
//  Fish.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

// MARK: - Fish Model
struct Fish: Identifiable, Codable, Hashable {
  let id: UUID
  let name: String
  let imageName: String
  let rarity: FishRarity
  let size: FishSize

  init(name: String, imageName: String, rarity: FishRarity, size: FishSize) {
    self.id = UUID()
    self.name = name
    self.imageName = imageName
    self.rarity = rarity
    self.size = size
  }

  // Custom Codable implementation to handle UUID properly
  enum CodingKeys: String, CodingKey {
    case id, name, imageName, rarity, size
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    imageName = try container.decode(String.self, forKey: .imageName)
    rarity = try container.decode(FishRarity.self, forKey: .rarity)
    size = try container.decode(FishSize.self, forKey: .size)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(imageName, forKey: .imageName)
    try container.encode(rarity, forKey: .rarity)
    try container.encode(size, forKey: .size)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: Fish, rhs: Fish) -> Bool {
    lhs.id == rhs.id
  }
} 