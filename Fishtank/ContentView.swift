//
//  ContentView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var fishTankManager = FishTankManager.shared
  @StateObject private var commitmentManager = CommitmentManager.shared
  @StateObject private var statsManager = GameStatsManager.shared
  @StateObject private var bubbleManager = BubbleManager.shared

  @State private var currentTime = Date()
  @State private var appStartTime = Date()
  @State private var timeSpent: TimeInterval = 0
  @State private var showCommitmentSelection = false
  @State private var showFishCollection = false
  @State private var showSettings = false
  @State private var showReward = false
  @State private var rewardMessage = ""
  @State private var notificationTimer: DispatchWorkItem?
  @State private var showCaseOpening = false
  @State private var caseOpeningLootbox: CommitmentLootbox?
  @State private var caseOpeningRewards: [CollectedFish] = []
  @State private var showAppRestrictionAlert = false
  @State private var showSkipConfirmation = false
  @State private var showCancelConfirmation = false

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  private let fishTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()  // 60 FPS
  private let bubbleTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

  // Time-based background colors
  private var timeBasedBackground: (topColor: Color, bottomColor: Color) {
    let hour = Calendar.current.component(.hour, from: currentTime)

    switch hour {
    case 5..<7:  // Early morning (5-7 AM) - Dawn
      return (Color.orange.opacity(0.2), Color.pink.opacity(0.15))
    case 7..<10:  // Morning (7-10 AM) - Bright morning
      return (Color.cyan.opacity(0.25), Color.blue.opacity(0.3))
    case 10..<16:  // Day (10 AM-4 PM) - Bright day
      return (Color.cyan.opacity(0.6), Color.blue.opacity(0.7))
    case 16..<19:  // Afternoon (4-7 PM) - Golden hour
      return (Color.orange.opacity(0.5), Color.yellow.opacity(0.4))
    case 19..<21:  // Evening (7-9 PM) - Sunset
      return (Color.pink.opacity(0.4), Color.orange.opacity(0.5))
    case 21..<23:  // Night (9-11 PM) - Early night
      return (Color.purple.opacity(0.4), Color.blue.opacity(0.6))
    case 23...23, 0..<5:  // Late night (11 PM-5 AM) - Deep night
      return (Color.black.opacity(0.25), Color.purple.opacity(0.3))
    default:
      return (Color.cyan.opacity(0.2), Color.blue.opacity(0.25))
    }
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        LinearGradient(
          colors: [timeBasedBackground.topColor, timeBasedBackground.bottomColor],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        // Animated Bubbles
        ForEach(bubbleManager.bubbles) { bubble in
          BubbleView(bubble: bubble)
            .position(x: bubble.x, y: bubble.y)
        }

        // Swimming Fish
        ForEach(fishTankManager.swimmingFish) { fish in
          SwimmingFishView(fish: fish, fishTankManager: fishTankManager)
            .position(x: fish.x, y: fish.y)
        }

        // Commitment Lootboxes
        ForEach(fishTankManager.commitmentLootboxes) { lootbox in
          LootboxView(type: lootbox.type)
            .position(x: lootbox.x, y: lootbox.y)
            .onTapGesture {
              // Generate possible rewards for the wheel
              var possibleRewards: [CollectedFish] = []
              for _ in 0..<(lootbox.type.fishCount * 10) {  // Generate more options for variety
                let fish = FishDatabase.randomFish(from: lootbox.type)
                let collectedFish = CollectedFish(fish: fish)
                possibleRewards.append(collectedFish)
              }

              caseOpeningLootbox = lootbox
              caseOpeningRewards = possibleRewards
              showCaseOpening = true
            }
        }

        VStack {
          // Top Bar
          HStack {
            ClockDisplayView(currentTime: currentTime)
              .padding(.leading, 25)
              .padding(.top, 40)

            Spacer()

            Button(action: {
              showSettings = true
            }) {
              Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.white)
                .opacity(0.6)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
            }
            .padding(.trailing, 25)
          }
          .padding(.top, 20)

          // Commitment Progress
          if let commitment = commitmentManager.currentCommitment {
            CommitmentProgressView(
              commitment: commitment,
              progress: commitmentManager.progress,
              timeRemaining: commitmentManager.timeRemaining
            )
            .padding(.top, 35)
          }

          Spacer()

          // Bottom Action Buttons
          HStack(spacing: 12) {
            if !commitmentManager.isActive {
              Button(action: {
                showCommitmentSelection = true
              }) {
                HStack(spacing: 8) {
                  Image(systemName: "target")
                    .font(.title3)
                  Text("Focus")
                    .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .overlay(
                      RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                )
              }
            } else {
              Button(action: {
                showCancelConfirmation = true
              }) {
                HStack(spacing: 8) {
                  Image(systemName: "xmark.circle")
                    .font(.title3)
                  Text("Cancel")
                    .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.2))
                    .overlay(
                      RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                )
              }

              Button(action: {
                showSkipConfirmation = true
              }) {
                HStack(spacing: 8) {
                  Image(systemName: "creditcard")
                    .font(.title3)
                  Text("Skip")
                    .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.2))
                    .overlay(
                      RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                )
              }
            }

            Button(action: {
              showFishCollection = true
            }) {
              HStack(spacing: 8) {
                Image(systemName: "fish")
                  .font(.title3)
                Text("Collection")
                  .font(.headline)
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(.ultraThinMaterial.opacity(0.4))
                  .overlay(
                    RoundedRectangle(cornerRadius: 16)
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
            }
          }
          .padding(.horizontal, 25)
          .padding(.bottom, 30)
        }

        RewardNotificationView(message: rewardMessage, isVisible: showReward)

        if showCommitmentSelection {
          CommitmentSelectionView(isPresented: $showCommitmentSelection) { commitment in
            // Check if Screen Time permissions are enabled
            if !commitmentManager.isAppRestrictionEnabled {
              // Request authorization first
              commitmentManager.requestAppRestrictionAuthorization()

              // Show alert if still not authorized after request
              if !commitmentManager.isAppRestrictionEnabled {
                showAppRestrictionAlert = true
                return
              }
            }

            // Start the commitment only if permissions are enabled
            commitmentManager.startCommitment(commitment)
            showRewardMessage(
              "🎯 \(commitment.rawValue) focus session started!\n📱 Other apps are now blocked!")
          }
        }

        if showFishCollection {
          FishCollectionView(
            collectedFish: statsManager.collectedFish,
            onFishSelected: { fish in
              // toggle visibility
              statsManager.toggleFishVisibility(fish, fishTankManager: fishTankManager)
            },
            onVisibilityToggled: { fish in
              let success = statsManager.toggleFishVisibility(
                fish, fishTankManager: fishTankManager)
              return success
            },
            onFishRenamed: { fishId, newName in
              // Update fish name in persistent storage
              let updatedFish = PersistentStorageManager.renameFish(id: fishId, newName: newName)
              
              // Find the fish in the updated collection for the confirmation message
              let renamedFish = updatedFish.first(where: { $0.id == fishId })
              
              // Update the fish in the stats manager
              statsManager.updateFishCollection(updatedFish)
              
              // Update swimming fish with the new name
              fishTankManager.renameFish(id: fishId, newName: newName)
              
              // Show confirmation message
              if let fish = renamedFish {
                let shinyIndicator = fish.isShiny ? " ✨" : ""
                if newName == fish.fish.name {
                  showRewardMessage("🐠 Name reset to species: \(newName)\(shinyIndicator)")
                } else {
                  showRewardMessage("🐠 \(newName) the \(fish.fish.name) renamed!\(shinyIndicator)")
                }
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
            // Handle completion - add fishes and remove lootbox
            fishTankManager.removeLootbox(lootbox)
            statsManager.addFishes(selectedFishes, fishTankManager: fishTankManager)

            let fishMessages = selectedFishes.map { fish in
              let shinyIndicator = fish.isShiny ? " ✨" : ""
              return "\(fish.rarity.rawValue) \(fish.name)\(shinyIndicator)"
            }
            let hiddenCount = selectedFishes.filter { !$0.isVisible }.count
            let hiddenMessage = hiddenCount > 0 ? "\n(\(hiddenCount) auto-hidden - tank full)" : ""
            let shinyCount = selectedFishes.filter { $0.isShiny }.count
            let shinyMessage = shinyCount > 0 ? "\n✨ \(shinyCount) shiny fish!" : ""
            showRewardMessage(
              "🎉 \(lootbox.type.rawValue) lootbox opened!\n\(selectedFishes.count) fish obtained:\n\(fishMessages.joined(separator: ", "))\(hiddenMessage)\(shinyMessage)"
            )

            // Reset state
            caseOpeningLootbox = nil
            caseOpeningRewards = []
          }
        }

        if showSkipConfirmation, let commitment = commitmentManager.currentCommitment {
          SkipConfirmationView(
            isPresented: $showSkipConfirmation,
            commitment: commitment,
            commitmentManager: commitmentManager
          ) { skippedCommitment in
            // Handle successful skip
            fishTankManager.spawnLootbox(type: skippedCommitment.lootboxType)
            showRewardMessage(
              "💳 \(skippedCommitment.rawValue) skipped! \(skippedCommitment.lootboxType.emoji) \(skippedCommitment.lootboxType.rawValue) lootbox earned!\n📱 App restrictions removed."
            )
          }
        }
      }
    }
    .alert("Cancel Focus Session?", isPresented: $showCancelConfirmation) {
      Button("Yes", role: .destructive) {
        if let cancelled = commitmentManager.cancelCommitment() {
          // Get a random fish from all collected fish
          if let randomFish = statsManager.collectedFish.randomElement() {
            // Remove the fish from collection and update swimming fish
            statsManager.removeFish(randomFish)
            fishTankManager.updateSwimmingFish(with: statsManager.getVisibleFish())
            let shinyIndicator = randomFish.isShiny ? " ✨" : ""
            showRewardMessage(
              "🚨 \(cancelled.rawValue) session cancelled.\n😢 \(randomFish.name) swam away forever!\(shinyIndicator)\nApp restrictions removed."
            )
          } else {
            showRewardMessage(
              "🚨 \(cancelled.rawValue) session cancelled.\nApp restrictions removed.")
          }
        }
      }
      Button("No", role: .cancel) {}
    } message: {
      Text("If you cancel, one of your fish will swim away FOREVER! Are you sure?")
    }
    .onReceive(timer) { _ in
      currentTime = Date()
      timeSpent = Date().timeIntervalSince(appStartTime)

      // Check progress in foreground
      if let completedCommitment = commitmentManager.checkBackgroundProgress() {
        fishTankManager.spawnLootbox(type: completedCommitment.lootboxType)
        showRewardMessage(
          "🏆 \(completedCommitment.rawValue) completed! \(completedCommitment.lootboxType.emoji) \(completedCommitment.lootboxType.rawValue) lootbox earned!\n📱 App restrictions removed."
        )
      }
    }
    .onReceive(fishTimer) { _ in
      fishTankManager.animateFish()
    }
    .onReceive(bubbleTimer) { _ in
      bubbleManager.animateBubbles()
    }
    .onAppear {
      appStartTime = Date()
      // Initialize swimming fish with all visible fish
      fishTankManager.updateSwimmingFish(with: statsManager.getVisibleFish())
    }
  }

  private func showRewardMessage(_ message: String) {
    // Cancel any existing notification timer to prevent glitches
    notificationTimer?.cancel()

    rewardMessage = message
    withAnimation(.spring()) {
      showReward = true
    }

    // Create a new timer and store it so we can cancel it if needed
    let newTimer = DispatchWorkItem {
      withAnimation(.spring()) {
        showReward = false
      }
    }
    notificationTimer = newTimer

    DispatchQueue.main.asyncAfter(
      deadline: .now() + AppConfig.rewardDisplayDuration, execute: newTimer)
  }
}

#Preview {
  ContentView()
}
