//
//  Models.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Configuration
struct AppConfig {
    static let maxFishCount = 15
    static let initialFishCount = 3
    static let fishSpawnInterval: TimeInterval = 30
    static let giftBoxInterval: TimeInterval = 600 // 10 minutes
    static let rewardDisplayDuration: TimeInterval = 4
}

// MARK: - Focus Commitment
enum FocusCommitment: String, CaseIterable {
    case test = "1 Second"
    case short = "10 Minutes"
    case medium = "1 Hour"
    case long = "4 Hours"
    
    var duration: TimeInterval {
        switch self {
        case .test: return 1
        case .short: return 600
        case .medium: return 3600
        case .long: return 14400
        }
    }
    
    var lootboxType: LootboxType {
        switch self {
        case .test: return .basic
        case .short: return .silver
        case .medium: return .gold
        case .long: return .platinum
        }
    }
    
    var emoji: String {
        switch self {
        case .test: return "⚡"
        case .short: return "🕐"
        case .medium: return "⏰"
        case .long: return "🏆"
        }
    }
}

// MARK: - Lootbox Types
enum LootboxType: String, CaseIterable {
    case basic = "Basic"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    
    var color: Color {
        switch self {
        case .basic: return .gray
        case .silver: return .secondary
        case .gold: return .yellow
        case .platinum: return .purple
        }
    }
    
    var fishCount: Int {
        switch self {
        case .basic: return 1
        case .silver: return 2
        case .gold: return 4
        case .platinum: return 6
        }
    }
    
    var rarityBoost: Double {
        switch self {
        case .basic: return 1.0
        case .silver: return 1.5
        case .gold: return 2.0
        case .platinum: return 3.0
        }
    }
    
    var emoji: String {
        switch self {
        case .basic: return "📦"
        case .silver: return "🎁"
        case .gold: return "💎"
        case .platinum: return "👑"
        }
    }
}

// MARK: - Fish Rarity
enum FishRarity: String, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var probability: Double {
        switch self {
        case .common: return 0.50
        case .uncommon: return 0.30
        case .rare: return 0.15
        case .epic: return 0.04
        case .legendary: return 0.01
        }
    }
    
    var emojis: [String] {
        switch self {
        case .common: return ["🐟", "🐠"]
        case .uncommon: return ["🐡", "🦈"]
        case .rare: return ["🐙", "🦑"]
        case .epic: return ["🐳", "🦭"]
        case .legendary: return ["🐉", "🦄"]
        }
    }
    
    static func randomRarity(boost: Double = 1.0) -> FishRarity {
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        let boostedProbabilities = FishRarity.allCases.map { rarity in
            switch rarity {
            case .common:
                return max(0.1, rarity.probability / boost)
            case .legendary:
                return min(0.3, rarity.probability * boost)
            default:
                return min(0.4, rarity.probability * (1 + (boost - 1) * 0.5))
            }
        }
        
        let total = boostedProbabilities.reduce(0, +)
        let normalizedProbabilities = boostedProbabilities.map { $0 / total }
        
        for (index, probability) in normalizedProbabilities.enumerated() {
            cumulative += probability
            if random <= cumulative {
                return FishRarity.allCases[index]
            }
        }
        return .common
    }
}

// MARK: - Game Objects
struct Fish: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var speed: CGFloat
    var direction: CGFloat
    var rarity: FishRarity
    var emoji: String
    
    static func random(in bounds: CGRect, rarity: FishRarity? = nil) -> Fish {
        let fishRarity = rarity ?? FishRarity.randomRarity()
        return Fish(
            x: CGFloat.random(in: 0...bounds.width),
            y: CGFloat.random(in: bounds.height * 0.2...bounds.height * 0.8),
            color: fishRarity.color,
            size: CGFloat.random(in: 15...30),
            speed: CGFloat.random(in: 0.5...2.0),
            direction: CGFloat.random(in: -1...1),
            rarity: fishRarity,
            emoji: fishRarity.emojis.randomElement()!
        )
    }
}

struct GiftBox: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
}

struct CommitmentLootbox: Identifiable {
    let id = UUID()
    let type: LootboxType
    let x: CGFloat
    let y: CGFloat
} 