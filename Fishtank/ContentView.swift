//
//  ContentView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var fishTankManager = FishTankManager(bounds: UIScreen.main.bounds)
  @StateObject private var commitmentManager = CommitmentManager()
  @StateObject private var statsManager = GameStatsManager()

  @State private var currentTime = Date()
  @State private var appStartTime = Date()
  @State private var timeSpent: TimeInterval = 0
  @State private var showCommitmentSelection = false
  @State private var showFishCollection = false
  @State private var showSettings = false
  @State private var showReward = false
  @State private var rewardMessage = ""
  @State private var cancelledCommitment: FocusCommitment?
  @State private var notificationTimer: DispatchWorkItem?
  @State private var showCaseOpening = false
  @State private var caseOpeningLootbox: CommitmentLootbox?
  @State private var caseOpeningRewards: [CollectedFish] = []

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  private let fishTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        LinearGradient(
          colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.6)],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        // Swimming Fish
        ForEach(fishTankManager.swimmingFish) { fish in
          SwimmingFishView(fish: fish)
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
                let rarity = FishRarity.randomRarity(boost: lootbox.type.rarityBoost)
                let fish = CollectedFish(rarity: rarity)
                possibleRewards.append(fish)
              }

              caseOpeningLootbox = lootbox
              caseOpeningRewards = possibleRewards
              showCaseOpening = true
            }
        }

        VStack {
          HStack {
            ClockDisplayView(currentTime: currentTime)
            Spacer()
            Button(action: {
              showSettings = true
            }) {
              Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.white)
                .opacity(0.4)
            }
            .padding(.trailing)
          }

          if let commitment = commitmentManager.currentCommitment {
            CommitmentProgressView(
              commitment: commitment,
              progress: commitmentManager.progress,
              timeRemaining: commitmentManager.timeRemaining
            )
          }

          Spacer()

          HStack(spacing: 15) {
            if !commitmentManager.isActive {
              Button(action: {
                showCommitmentSelection = true
              }) {
                Text("🎯 Start Focus Session")
                  .font(.headline)
                  .foregroundColor(.white)
                  .opacity(0.85)
                  .padding()
                  .background(
                    RoundedRectangle(cornerRadius: 10)
                      .fill(.ultraThinMaterial)
                      .overlay(
                        RoundedRectangle(cornerRadius: 10)
                          .stroke(Color.white.opacity(0.2), lineWidth: 1)
                      )
                  )
              }
            }

            Button(action: {
              showFishCollection = true
            }) {
              Text("🐠 View Collection")
                .font(.headline)
                .foregroundColor(.white)
                .opacity(0.85)
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .overlay(
                      RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                )
            }
          }
          .padding(.bottom, 30)
        }

        RewardNotificationView(message: rewardMessage, isVisible: showReward)

        if showCommitmentSelection {
          CommitmentSelectionView(isPresented: $showCommitmentSelection) { commitment in
            commitmentManager.startCommitment(commitment)
            showRewardMessage("🎯 \(commitment.rawValue) focus session started!")
          }
        }

        if showFishCollection {
          FishCollectionView(
            collectedFish: statsManager.collectedFish,
            onFishSelected: { fish in
              // Fish selection no longer adds to swimming - visibility controls this
              showRewardMessage("🐠 \(fish.emoji) visibility controls swimming display!")
            },
            onVisibilityToggled: { fish in
              let wasVisible = fish.isVisible
              let success = statsManager.toggleFishVisibility(
                fish, fishTankManager: fishTankManager)
              return success
            },
            isPresented: $showFishCollection
          )
        }

        if showSettings {
          SettingsView(
            isPresented: $showSettings,
            statsManager: statsManager
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

            let fishMessages = selectedFishes.map { "\($0.rarity.rawValue) \($0.emoji)" }
            let hiddenCount = selectedFishes.filter { !$0.isVisible }.count
            let hiddenMessage = hiddenCount > 0 ? "\n(\(hiddenCount) auto-hidden - tank full)" : ""
            showRewardMessage(
              "🎉 \(lootbox.type.rawValue) lootbox opened!\n\(selectedFishes.count) fish obtained:\n\(fishMessages.joined(separator: ", "))\(hiddenMessage)"
            )

            // Reset state
            caseOpeningLootbox = nil
            caseOpeningRewards = []
          }
        }
      }
    }
    .onReceive(timer) { _ in
      currentTime = Date()
      timeSpent = Date().timeIntervalSince(appStartTime)

      if let completedCommitment = commitmentManager.checkProgress() {
        fishTankManager.spawnLootbox(type: completedCommitment.lootboxType)
        showRewardMessage(
          "🏆 \(completedCommitment.rawValue) completed! \(completedCommitment.lootboxType.emoji) \(completedCommitment.lootboxType.rawValue) lootbox earned!"
        )
      }
    }
    .onReceive(fishTimer) { _ in
      fishTankManager.animateFish()
    }
    .onAppear {
      appStartTime = Date()
      // Initialize swimming fish with all visible fish
      fishTankManager.updateSwimmingFish(with: statsManager.getVisibleFish())
    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
    ) { _ in
      // Cancel focus session when app goes to background (silently)
      if let cancelled = commitmentManager.cancelCommitment() {
        cancelledCommitment = cancelled
      }
    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
    ) { _ in
      // Show notification when user returns to app if session was cancelled
      if let cancelled = cancelledCommitment {
        showRewardMessage(
          "🚨 Focus session cancelled - app was backgrounded\n\(cancelled.emoji) \(cancelled.rawValue) session ended"
        )
        cancelledCommitment = nil  // Clear the stored cancellation
      }
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
