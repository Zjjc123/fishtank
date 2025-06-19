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
                .opacity(0.8)
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
                  .padding()
                  .background(Color.green.opacity(0.8))
                  .cornerRadius(10)
              }
            }

            Button(action: {
              showFishCollection = true
            }) {
              Text("🐠 View Collection")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue.opacity(0.8))
                .cornerRadius(10)
            }
          }
          .padding(.bottom, 30)
        }

        // Swimming Fish
        ForEach(fishTankManager.swimmingFish) { fish in
          SwimmingFishView(fish: fish)
            .position(x: fish.x, y: fish.y)
        }

        // Gift Boxes
        ForEach(fishTankManager.giftBoxes) { giftBox in
          GiftBoxView()
            .position(x: giftBox.x, y: giftBox.y)
            .onTapGesture {
              let newFish = fishTankManager.openGiftBox(giftBox)
              statsManager.addFish(newFish, fishTankManager: fishTankManager)
              showRewardMessage("🎉 \(newFish.rarity.rawValue) \(newFish.emoji) fish obtained!")
            }
        }

        // Commitment Lootboxes
        ForEach(fishTankManager.commitmentLootboxes) { lootbox in
          LootboxView(type: lootbox.type)
            .position(x: lootbox.x, y: lootbox.y)
            .onTapGesture {
              let newFishes = fishTankManager.openLootbox(lootbox)
              statsManager.addFishes(newFishes, fishTankManager: fishTankManager)

              let fishMessages = newFishes.map { "\($0.rarity.rawValue) \($0.emoji)" }
              showRewardMessage(
                "🎉 \(lootbox.type.rawValue) lootbox opened!\n\(newFishes.count) fish obtained:\n\(fishMessages.joined(separator: ", "))"
              )
            }
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
              statsManager.toggleFishVisibility(fish, fishTankManager: fishTankManager)
              let status = fish.isVisible ? "visible" : "hidden"
              showRewardMessage("🐠 \(fish.emoji) is now \(status)")
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
      }
    }
    .onReceive(timer) { _ in
      currentTime = Date()
      timeSpent = Date().timeIntervalSince(appStartTime)

      if fishTankManager.spawnGiftBoxIfNeeded(timeSpent: timeSpent) {
        showRewardMessage("🎁 Gift box appeared! Tap to open!")
      }

      if let completedCommitment = commitmentManager.checkProgress() {
        fishTankManager.spawnCommitmentLootbox(type: completedCommitment.lootboxType)
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
    rewardMessage = message
    withAnimation(.spring()) {
      showReward = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.rewardDisplayDuration) {
      withAnimation(.spring()) {
        showReward = false
      }
    }
  }
}

#Preview {
  ContentView()
}
