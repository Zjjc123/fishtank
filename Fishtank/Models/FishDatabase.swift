//
//  FishDatabase.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

// MARK: - Fish Database
struct FishDatabase {
  static let allFish: [Fish] = [
    // Common Fish
    Fish(name: "Minnow", imageName: "Minnow", rarity: .common, size: .tiny),
    Fish(name: "Anchovy", imageName: "Anchovy", rarity: .common, size: .tiny),
    Fish(name: "Tetra", imageName: "Tetra", rarity: .common, size: .small),
    Fish(name: "Perch", imageName: "Perch", rarity: .common, size: .small),
    Fish(name: "Sardine", imageName: "Sardine", rarity: .common, size: .tiny),
    Fish(name: "Mackerel", imageName: "Mackerel", rarity: .common, size: .small),
    Fish(name: "Molly", imageName: "Molly", rarity: .common, size: .small),
    Fish(name: "Platy", imageName: "Platy", rarity: .common, size: .small),
    Fish(name: "Zebrafish", imageName: "Zebrafish", rarity: .common, size: .small),
    Fish(name: "Killifish", imageName: "Killifish", rarity: .common, size: .small),
    Fish(name: "Tilapia", imageName: "Tilapia", rarity: .common, size: .medium),
    Fish(name: "Goby", imageName: "Goby", rarity: .common, size: .small),
    Fish(name: "Smelt", imageName: "Smelt", rarity: .common, size: .tiny),
    Fish(name: "Chub", imageName: "Chub", rarity: .common, size: .small),
    Fish(name: "Dace", imageName: "Dace", rarity: .common, size: .small),
    Fish(name: "Roach", imageName: "Roach", rarity: .common, size: .small),

    // Uncommon Fish
    Fish(name: "Cod", imageName: "Cod", rarity: .uncommon, size: .medium),
    Fish(name: "Pike", imageName: "Pike", rarity: .uncommon, size: .medium),
    Fish(name: "Salmon", imageName: "Salmon", rarity: .uncommon, size: .medium),
    Fish(name: "Guppy", imageName: "Guppy", rarity: .uncommon, size: .small),
    Fish(name: "Goldfish", imageName: "Goldfish", rarity: .uncommon, size: .small),
    Fish(name: "Flying Fish", imageName: "Flying Fish", rarity: .uncommon, size: .small),
    Fish(name: "Mudskipper", imageName: "Mudskipper", rarity: .uncommon, size: .small),
    Fish(name: "Neon Tetra", imageName: "Neon Tetra", rarity: .uncommon, size: .small),
    Fish(name: "Glass Catfish", imageName: "Glass Catfish", rarity: .uncommon, size: .small),
    Fish(name: "Gourami", imageName: "Gourami", rarity: .uncommon, size: .small),

    // Rare Fish
    Fish(name: "Sturgeon", imageName: "Sturgeon", rarity: .rare, size: .large),
    Fish(name: "Tuna", imageName: "Tuna", rarity: .rare, size: .large),
    Fish(name: "Marlin", imageName: "Marlin", rarity: .rare, size: .large),
    Fish(name: "Barracuda", imageName: "Barracuda", rarity: .rare, size: .medium),
    Fish(name: "Electric Eel", imageName: "Electric Eel", rarity: .rare, size: .large),
    Fish(name: "Arctic Char", imageName: "Arctic Char", rarity: .rare, size: .medium),
    Fish(name: "Haddock", imageName: "Haddock", rarity: .rare, size: .medium),
    Fish(name: "Red Snapper", imageName: "Red Snapper", rarity: .rare, size: .medium),
    Fish(name: "Rockfish", imageName: "Rockfish", rarity: .rare, size: .medium),
    Fish(name: "Jellyfish", imageName: "Jellyfish", rarity: .rare, size: .medium),
    Fish(name: "Arapaima", imageName: "Arapaima", rarity: .rare, size: .huge),

    // Epic Fish
    Fish(name: "Shark", imageName: "Shark", rarity: .epic, size: .huge),
    Fish(name: "Dolphin", imageName: "Dolphin", rarity: .epic, size: .large),
    Fish(name: "Giant Squid", imageName: "Giant Squid", rarity: .epic, size: .huge),
    Fish(name: "Sawfish", imageName: "Sawfish", rarity: .epic, size: .large),
    Fish(name: "Tarpon", imageName: "Tarpon", rarity: .epic, size: .large),
    Fish(name: "Sea Turtle", imageName: "Sea Turtle", rarity: .epic, size: .large),
    Fish(name: "Ocean Sunfish", imageName: "Ocean Sunfish", rarity: .epic, size: .huge),
    Fish(name: "Narwhal", imageName: "Narwhal", rarity: .epic, size: .large),
    Fish(name: "Beluga Whale", imageName: "Beluga Whale", rarity: .epic, size: .large),
    Fish(name: "Yellow Fin Tuna", imageName: "Yellow Fin Tuna", rarity: .epic, size: .large),

    // Legendary Fish
    Fish(name: "Manta Ray", imageName: "Manta Ray", rarity: .legendary, size: .huge),
    Fish(name: "Coelacanth", imageName: "Coelacanth", rarity: .legendary, size: .large),
    Fish(name: "Giant Oarfish", imageName: "Giant Oarfish", rarity: .legendary, size: .huge),
    Fish(name: "Blue Whale", imageName: "Blue Whale", rarity: .legendary, size: .giant),
    Fish(name: "Orca", imageName: "Orca", rarity: .legendary, size: .giant),
    Fish(name: "Megalodon", imageName: "Megalodon", rarity: .legendary, size: .giant),

    // Mythic Fish
    Fish(name: "Leviathan", imageName: "Leviathan", rarity: .mythic, size: .giant),
    Fish(name: "Kraken", imageName: "Kraken", rarity: .mythic, size: .giant),
    Fish(name: "Loch Ness Monster", imageName: "Loch Ness Monster", rarity: .mythic, size: .giant),
    Fish(name: "Sea Serpent", imageName: "Sea Serpent", rarity: .mythic, size: .giant),

    // Unique Fish
    Fish(name: "Clownfish", imageName: "Clownfish", rarity: .unique, size: .small),
  ]

  static func fishByRarity(_ rarity: FishRarity) -> [Fish] {
    return allFish.filter { $0.rarity == rarity }
  }

  static func fishBySize(_ size: FishSize) -> [Fish] {
    return allFish.filter { $0.size == size }
  }

  static func randomFish(from lootbox: LootboxType, isSpinner: Bool = false) -> Fish {
    let rarity = FishRarity.randomRarity(from: lootbox, isSpinner: isSpinner)
    let fishOfRarity = fishByRarity(rarity)
    return fishOfRarity.randomElement()!
  }

  static func randomFish(of rarity: FishRarity) -> Fish {
    let fishOfRarity = fishByRarity(rarity)
    return fishOfRarity.randomElement()!
  }
}
