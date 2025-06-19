//
//  Managers.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Fish Tank Manager
class FishTankManager: ObservableObject {
    @Published var fishes: [Fish] = []
    @Published var giftBoxes: [GiftBox] = []
    @Published var commitmentLootboxes: [CommitmentLootbox] = []
    
    private var lastGiftBoxTime: TimeInterval = 0
    private let bounds: CGRect
    
    init(bounds: CGRect) {
        self.bounds = bounds
        spawnInitialFish()
    }
    
    func updateBounds(_ newBounds: CGRect) {
        // Update bounds if needed for screen rotation, etc.
    }
    
    func spawnInitialFish() {
        for _ in 0..<AppConfig.initialFishCount {
            fishes.append(Fish.random(in: bounds))
        }
    }
    
    func spawnFishIfNeeded(timeSpent: TimeInterval) {
        if Int(timeSpent) % Int(AppConfig.fishSpawnInterval) == 0 
            && Int(timeSpent) > 0 
            && fishes.count < AppConfig.maxFishCount {
            fishes.append(Fish.random(in: bounds))
        }
    }
    
    func animateFish() {
        for i in fishes.indices {
            fishes[i].x += fishes[i].speed * fishes[i].direction
            
            if fishes[i].x <= 0 || fishes[i].x >= bounds.width {
                fishes[i].direction *= -1
            }
            
            fishes[i].x = max(0, min(bounds.width, fishes[i].x))
        }
    }
    
    func spawnGiftBoxIfNeeded(timeSpent: TimeInterval) -> Bool {
        let minutes = Int(timeSpent) / 60
        if timeSpent >= lastGiftBoxTime + AppConfig.giftBoxInterval && minutes > 0 {
            spawnGiftBox()
            lastGiftBoxTime = timeSpent
            return true
        }
        return false
    }
    
    private func spawnGiftBox() {
        let giftBox = GiftBox(
            x: CGFloat.random(in: 50...bounds.width - 50),
            y: CGFloat.random(in: bounds.height * 0.3...bounds.height * 0.7)
        )
        giftBoxes.append(giftBox)
    }
    
    func openGiftBox(_ giftBox: GiftBox) -> Fish {
        if let index = giftBoxes.firstIndex(where: { $0.id == giftBox.id }) {
            giftBoxes.remove(at: index)
        }
        
        let rarity = FishRarity.randomRarity()
        let newFish = Fish.random(in: bounds, rarity: rarity)
        fishes.append(newFish)
        
        return newFish
    }
    
    func spawnCommitmentLootbox(type: LootboxType) {
        let lootbox = CommitmentLootbox(
            type: type,
            x: CGFloat.random(in: 50...bounds.width - 50),
            y: CGFloat.random(in: bounds.height * 0.3...bounds.height * 0.7)
        )
        commitmentLootboxes.append(lootbox)
    }
    
    func openLootbox(_ lootbox: CommitmentLootbox) -> [Fish] {
        if let index = commitmentLootboxes.firstIndex(where: { $0.id == lootbox.id }) {
            commitmentLootboxes.remove(at: index)
        }
        
        var newFishes: [Fish] = []
        for _ in 0..<lootbox.type.fishCount {
            let rarity = FishRarity.randomRarity(boost: lootbox.type.rarityBoost)
            let newFish = Fish.random(in: bounds, rarity: rarity)
            fishes.append(newFish)
            newFishes.append(newFish)
        }
        
        return newFishes
    }
}

// MARK: - Commitment Manager
class CommitmentManager: ObservableObject {
    @Published var currentCommitment: FocusCommitment?
    @Published var commitmentStartTime: Date?
    
    var progress: Double {
        guard let commitment = currentCommitment,
              let startTime = commitmentStartTime else { return 0 }
        
        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / commitment.duration, 1.0)
    }
    
    var timeRemaining: TimeInterval {
        guard let commitment = currentCommitment,
              let startTime = commitmentStartTime else { return 0 }
        
        let elapsed = Date().timeIntervalSince(startTime)
        return max(commitment.duration - elapsed, 0)
    }
    
    var isActive: Bool {
        currentCommitment != nil
    }
    
    func startCommitment(_ commitment: FocusCommitment) {
        currentCommitment = commitment
        commitmentStartTime = Date()
    }
    
    func checkProgress() -> FocusCommitment? {
        guard let commitment = currentCommitment,
              let startTime = commitmentStartTime else { return nil }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        if elapsed >= commitment.duration {
            let completedCommitment = commitment
            currentCommitment = nil
            commitmentStartTime = nil
            return completedCommitment
        }
        
        return nil
    }
}

// MARK: - Game Stats Manager
class GameStatsManager: ObservableObject {
    @Published var fishCount = 0
    @Published var fishCollection: [FishRarity: Int] = [:]
    
    init() {
        initializeFishCollection()
    }
    
    private func initializeFishCollection() {
        for rarity in FishRarity.allCases {
            fishCollection[rarity] = 0
        }
    }
    
    func addFish(_ fish: Fish) {
        fishCount += 1
        fishCollection[fish.rarity] = (fishCollection[fish.rarity] ?? 0) + 1
    }
    
    func addFishes(_ fishes: [Fish]) {
        for fish in fishes {
            addFish(fish)
        }
    }
} 