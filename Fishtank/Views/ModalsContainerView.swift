//
//  ModalsContainerView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct ModalsContainerView: View {
  // Managers
  @ObservedObject var commitmentManager: CommitmentManager
  @ObservedObject var statsManager: GameStateManager
  @ObservedObject var fishTankManager: FishTankManager
  @ObservedObject var supabaseManager: SupabaseManager
  
  // Modal states
  @Binding var showCommitmentSelection: Bool
  @Binding var showFishCollection: Bool
  @Binding var showSettings: Bool
  @Binding var showCaseOpening: Bool
  @Binding var caseOpeningLootbox: CommitmentLootbox?
  @Binding var caseOpeningRewards: [CollectedFish]
  
  // Callbacks
  let onCommitmentSelected: (FocusCommitment) -> Void
  let onLootboxOpened: ([CollectedFish]) -> Void
  let showRewardMessage: (String) -> Void
  
  var body: some View {
    ZStack {
      if showCommitmentSelection {
        CommitmentSelectionView(isPresented: $showCommitmentSelection) { commitment in
          onCommitmentSelected(commitment)
        }
      }

      if showFishCollection {
        FishCollectionView(
          collectedFish: statsManager.collectedFish,
          onFishSelected: { fish in
            // toggle visibility
            Task {
              await statsManager.toggleFishVisibility(fish, fishTankManager: fishTankManager)
            }
          },
          onVisibilityToggled: { fish in
            // Start the async operation but return immediately
            Task {
              _ = await statsManager.toggleFishVisibility(
                fish, fishTankManager: fishTankManager)
            }
            
            // Return true to indicate the toggle was initiated
            // The actual visibility change will happen asynchronously
            return true
          },
          onFishRenamed: { fishId, newName in
            // Update fish name in in-memory collection and Supabase
            if let index = statsManager.collectedFish.firstIndex(where: { $0.id == fishId }) {
              // Create a copy of the collection to modify
              var updatedCollection = statsManager.collectedFish
              updatedCollection[index].name = newName
              
              // Use Task for async operations
              Task {
                await statsManager.updateFishCollection(updatedCollection)
                
                // If authenticated, update the name in Supabase directly
                if supabaseManager.isAuthenticated {
                  await supabaseManager.updateFishNameInSupabase(fishId, customName: newName)
                }
              }
            }

            // Update swimming fish with the new name (non-async operation)
            fishTankManager.renameFish(id: fishId, newName: newName)

            // Show confirmation message (non-async operation)
            if let fish = statsManager.collectedFish.first(where: { $0.id == fishId }) {
              let shinyIndicator = fish.isShiny ? " ✨" : ""
              if newName == fish.fish.name {
                showRewardMessage("🐠 Name reset to species: \(newName)\(shinyIndicator)")
              } else {
                showRewardMessage(
                  "🐠 \(newName) the \(fish.fish.name) renamed!\(shinyIndicator)")
              }
            }
          },
          onFishDeleted: { fish in
            // Delete fish from collection and update tank
            Task {
              await statsManager.removeFish(fish, fishTankManager: fishTankManager)
              
              // Show confirmation message
              let shinyIndicator = fish.isShiny ? " ✨" : ""
              showRewardMessage("🗑️ \(fish.name) has been removed\(shinyIndicator)")
            }
          },
          isPresented: $showFishCollection
        )
      }

      if showSettings {
        SettingsView(
          isPresented: $showSettings,
          statsManager: statsManager,
          fishTankManager: fishTankManager
        )
      }

      if showCaseOpening, let lootbox = caseOpeningLootbox, !caseOpeningRewards.isEmpty {
        CaseOpeningWheelView(
          lootboxType: lootbox.type,
          possibleRewards: caseOpeningRewards,
          selectedReward: caseOpeningRewards.first!,  // First reward will be the "selected" one
          isPresented: $showCaseOpening
        ) { selectedFishes in
          onLootboxOpened(selectedFishes)
        }
      }


    }
  }
}

#Preview {
  ModalsContainerView(
    commitmentManager: CommitmentManager.shared,
    statsManager: GameStateManager.shared,
    fishTankManager: FishTankManager.shared,
    supabaseManager: SupabaseManager.shared,
    showCommitmentSelection: .constant(false),
    showFishCollection: .constant(false),
    showSettings: .constant(false),
    showCaseOpening: .constant(false),
    caseOpeningLootbox: .constant(nil),
    caseOpeningRewards: .constant([]),
    onCommitmentSelected: { _ in },
    onLootboxOpened: { _ in },
    showRewardMessage: { _ in }
  )
} 