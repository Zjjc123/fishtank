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
  @StateObject private var bubbleManager = BubbleManager(bounds: UIScreen.main.bounds)

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

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  private let fishTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
  private let bubbleTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

  // Time-based background colors
  private var timeBasedBackground: (topColor: Color, bottomColor: Color) {
    let hour = Calendar.current.component(.hour, from: currentTime)

    switch hour {
    case 5..<7:  // Early morning (5-7 AM) - Dawn
      return (Color.orange.opacity(0.3), Color.pink.opacity(0.25))
    case 7..<10:  // Morning (7-10 AM) - Bright morning
      return (Color.cyan.opacity(0.35), Color.blue.opacity(0.4))
    case 10..<16:  // Day (10 AM-4 PM) - Bright day
      return (Color.cyan.opacity(0.8), Color.blue.opacity(0.9))
    case 16..<19:  // Afternoon (4-7 PM) - Golden hour
      return (Color.orange.opacity(0.7), Color.yellow.opacity(0.6))
    case 19..<21:  // Evening (7-9 PM) - Sunset
      return (Color.pink.opacity(0.6), Color.orange.opacity(0.7))
    case 21..<23:  // Night (9-11 PM) - Early night
      return (Color.purple.opacity(0.6), Color.blue.opacity(0.8))
    case 23...23, 0..<5:  // Late night (11 PM-5 AM) - Deep night
      return (Color.black.opacity(0.35), Color.purple.opacity(0.4))
    default:
      return (Color.cyan.opacity(0.25), Color.blue.opacity(0.35))
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
            .padding(.top, 20)
          }

          HStack {
            ClockDisplayView(currentTime: currentTime)
              .padding(.leading, 30)
              .padding(.top, 50)
              .allowsHitTesting(false)
            Spacer()
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
            } else {
              Button(action: {
                if let cancelled = commitmentManager.cancelCommitment() {
                  showRewardMessage(
                    "🚨 \(cancelled.rawValue) session cancelled.\nApp restrictions removed.")
                }
              }) {
                Text("❌ Cancel Session")
                  .font(.headline)
                  .foregroundColor(.white)
                  .opacity(0.85)
                  .padding()
                  .background(
                    RoundedRectangle(cornerRadius: 10)
                      .fill(Color.red.opacity(0.5))
                      .overlay(
                        RoundedRectangle(cornerRadius: 10)
                          .stroke(Color.white.opacity(0.2), lineWidth: 1)
                      )
                  )
              }

              Button(action: {
                if let completed = commitmentManager.debugFinishCommitment() {
                  fishTankManager.spawnLootbox(type: completed.lootboxType)
                  showRewardMessage(
                    "🔧 DEBUG: \(completed.rawValue) instantly completed! \(completed.lootboxType.emoji) \(completed.lootboxType.rawValue) lootbox earned!\n📱 App restrictions removed."
                  )
                }
              }) {
                Text("🔧 Debug Finish")
                  .font(.headline)
                  .foregroundColor(.white)
                  .opacity(0.85)
                  .padding()
                  .background(
                    RoundedRectangle(cornerRadius: 10)
                      .fill(Color.orange.opacity(0.5))
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
            // Request app restriction authorization first
            commitmentManager.requestAppRestrictionAuthorization()

            // Start the commitment
            commitmentManager.startCommitment(commitment)

            // Show appropriate message based on authorization status
            if commitmentManager.isAppRestrictionEnabled {
              showRewardMessage(
                "🎯 \(commitment.rawValue) focus session started!\n📱 Other apps are now blocked!")
            } else {
              showRewardMessage(
                "🎯 \(commitment.rawValue) focus session started!\n⚠️ App blocking not available - please enable Screen Time permissions"
              )
              showAppRestrictionAlert = true
            }
          }
        }

        if showFishCollection {
          FishCollectionView(
            collectedFish: statsManager.collectedFish,
            onFishSelected: { fish in
              // Fish selection no longer adds to swimming - visibility controls this
              showRewardMessage("🐠 \(fish.name) visibility controls swimming display!")
            },
            onVisibilityToggled: { fish in
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

            let fishMessages = selectedFishes.map { "\($0.rarity.rawValue) \($0.name)" }
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
    .alert("Screen Time Permissions Required", isPresented: $showAppRestrictionAlert) {
      Button("Open Settings") {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
        }
      }
      Button("OK", role: .cancel) {}
    } message: {
      Text(
        "To block other apps during focus sessions, please enable Screen Time permissions in Settings > Screen Time > App Limits."
      )
    }
    .onReceive(timer) { _ in
      currentTime = Date()
      timeSpent = Date().timeIntervalSince(appStartTime)

      if let completedCommitment = commitmentManager.checkProgress() {
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
