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
  @StateObject private var statsManager = GameStateManager.shared
  @StateObject private var bubbleManager = BubbleManager.shared
  @StateObject private var supabaseManager = SupabaseManager.shared
  @StateObject private var userPreferences = UserPreferences.shared

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
  @State private var isRefreshingData = false
  @State private var isShareSheetPresented = false

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  private let fishTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()  // 60 FPS
  private let bubbleTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()  // 60 FPS
  private let dataRefreshTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()  // Refresh every 5 minutes

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        FishTankBackgroundView(currentTime: currentTime)

        // Fish tank environment (bubbles, fish, lootboxes)
        FishTankEnvironmentView(
          fishTankManager: fishTankManager,
          bubbleManager: bubbleManager,
          onLootboxTapped: { lootbox, rewards in
            caseOpeningLootbox = lootbox
            caseOpeningRewards = rewards
            showCaseOpening = true
          }
        )

        VStack {
          // Top Bar
          TopBarView(
            currentTime: currentTime,
            isSyncing: statsManager.isSyncing,
            onSettingsTapped: {
              showSettings = true
            },
            onShareTapped: {
              isShareSheetPresented = true
            },
            fishSpeciesCount: getUniqueSpeciesCount()
          )

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
          BottomActionBarView(
            isCommitmentActive: commitmentManager.isActive,
            onFocusTapped: {
              showCommitmentSelection = true
            },
            onCancelTapped: {
              showCancelConfirmation = true
            },
            onSkipTapped: {
              showSkipConfirmation = true
            },
            onCollectionTapped: {
              // Refresh data from Supabase before showing collection
              if supabaseManager.isAuthenticated && !statsManager.isSyncing {
                Task {
                  await statsManager.triggerSupabaseSync()
                }
              }
              showFishCollection = true
            }
          )
        }

        // Reward notification
        RewardNotificationView(message: rewardMessage, isVisible: showReward)

        // Modals container
        ModalsContainerView(
          commitmentManager: commitmentManager,
          statsManager: statsManager,
          fishTankManager: fishTankManager,
          supabaseManager: supabaseManager,
          showCommitmentSelection: $showCommitmentSelection,
          showFishCollection: $showFishCollection,
          showSettings: $showSettings,
          showCaseOpening: $showCaseOpening,
          showSkipConfirmation: $showSkipConfirmation,
          caseOpeningLootbox: $caseOpeningLootbox,
          caseOpeningRewards: $caseOpeningRewards,
          onCommitmentSelected: { commitment in
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
          },
          onLootboxOpened: { selectedFishes in
            // Handle completion - add fishes and remove lootbox
            if let lootbox = caseOpeningLootbox {
              fishTankManager.removeLootbox(lootbox)
              Task {
                do {
                  try await statsManager.addFishes(selectedFishes, fishTankManager: fishTankManager)
                } catch {
                  print("❌ Error adding fishes from lootbox: \(error)")
                }
              }

              let fishMessages = selectedFishes.map { fish in
                let shinyIndicator = fish.isShiny ? " ✨" : ""
                return "\(fish.rarity.rawValue) \(fish.name)\(shinyIndicator)"
              }
              let hiddenCount = selectedFishes.filter { !$0.isVisible }.count
              let hiddenMessage =
                hiddenCount > 0 ? "\n(\(hiddenCount) auto-hidden - tank full)" : ""
              let shinyCount = selectedFishes.filter { $0.isShiny }.count
              let shinyMessage = shinyCount > 0 ? "\n✨ \(shinyCount) shiny fish!" : ""
              showRewardMessage(
                "🎉 \(lootbox.type.rawValue) lootbox opened!\n\(selectedFishes.count) fish obtained:\n\(fishMessages.joined(separator: ", "))\(hiddenMessage)\(shinyMessage)"
              )

              // Reset state
              caseOpeningLootbox = nil
              caseOpeningRewards = []
            }
          },
          onSkipConfirmed: { skippedCommitment in
            // Handle successful skip
            fishTankManager.spawnLootbox(type: skippedCommitment.lootboxType)
            showRewardMessage(
              "💳 \(skippedCommitment.rawValue) skipped! \(skippedCommitment.lootboxType.emoji) \(skippedCommitment.lootboxType.rawValue) lootbox earned!\n📱 App restrictions removed."
            )
          },
          showRewardMessage: showRewardMessage
        )
      }
      .sheet(isPresented: $isShareSheetPresented) {
        createShareSheet()
      }
    }
    .onAppear {
      // Force landscape orientation and UI update
      UIDevice.current.setValue(
        UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
      AppDelegate.orientationLock = .landscape
      if #available(iOS 16.0, *) {
        UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .forEach {
            $0.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
          }
      } else {
        UIViewController.attemptRotationToDeviceOrientation()
      }

      appStartTime = Date()
      // Initialize swimming fish with all visible fish
      fishTankManager.updateSwimmingFish(with: statsManager.getVisibleFish())

      // Fetch latest data from Supabase if authenticated
      if supabaseManager.isAuthenticated && !statsManager.isSyncing {
        Task {
          await statsManager.triggerSupabaseSync()
        }
      }
      
      // Set up commitment completion callback
      commitmentManager.onCommitmentCompleted = { completedCommitment in
        showRewardMessage(
          "🏆 \(completedCommitment.rawValue) completed! \(completedCommitment.lootboxType.emoji) \(completedCommitment.lootboxType.rawValue) lootbox earned!\n📱 App restrictions removed."
        )
      }
    }
    // Remove orientation change notification handler
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
    { _ in
      // No need to update bounds on becoming active anymore
      // We're always using landscape bounds
    }
    .alert("Cancel Focus Session?", isPresented: $showCancelConfirmation) {
      Button("Yes", role: .destructive) {
        if let cancelled = commitmentManager.cancelCommitment() {
          // Get a random fish from all collected fish
          if let randomFish = statsManager.collectedFish.randomElement() {
            // Remove the fish from collection and update swimming fish
            Task {
              await statsManager.removeFish(randomFish, fishTankManager: fishTankManager)
              let shinyIndicator = randomFish.isShiny ? " ✨" : ""
              showRewardMessage(
                "🚨 \(cancelled.rawValue) session cancelled.\n😢 \(randomFish.name) swam away forever!\(shinyIndicator)\nApp restrictions removed."
              )
            }
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
    }
    .onReceive(fishTimer) { _ in
      fishTankManager.animateFish()
    }
    .onReceive(bubbleTimer) { _ in
      bubbleManager.animateBubbles()
    }
    .onReceive(dataRefreshTimer) { _ in
      // Refresh data from Supabase every 5 minutes if authenticated
      if supabaseManager.isAuthenticated && !statsManager.isSyncing {
        Task {
          await statsManager.triggerSupabaseSync()
        }
      }
    }
    .onChange(of: supabaseManager.isAuthenticated) { isAuthenticated in
      // When authentication state changes, refresh data
      if isAuthenticated && !statsManager.isSyncing {
        Task {
          await statsManager.triggerSupabaseSync()
        }
      }
    }
    // Update swimming fish whenever the collection changes
    .onChange(of: statsManager.collectedFish) { _ in
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

  // Helper function to create the share sheet content
  private func createShareSheet() -> ShareSheet {
    let uniqueSpecies = getUniqueSpeciesCount()
    let rarityCount = getRarityCount()
    
    var message = "🐠 I've collected \(uniqueSpecies) different fish species in my Fishtank!\n\n"
    
    // Add total focus time
    message += "⏱️ Total Focus Time: \(formatTimeInterval(statsManager.totalFocusTime))\n\n"

    // Add rarity breakdown
    message += "📊 My collection:\n"
    for (rarity, count) in rarityCount.sorted(by: { $0.key.sortOrder > $1.key.sortOrder }) {
      if count > 0 {
        message += "\(rarity.emoji) \(rarity.rawValue): \(count)\n"
      }
    }
    
    message += "\nDownload Fishtank - Focus App!"
    
    let appStoreURL = URL(string: "https://apps.apple.com/us/app/fishtank-focus-app/id6747935306")!
    
    let itemsToShare: [Any] = [message, appStoreURL]
    
    return ShareSheet(activityItems: itemsToShare)
  }
  
  // Helper function to format time interval
  private func formatTimeInterval(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes) minutes"
    }
  }

  // Helper function to get counts by rarity
  private func getRarityCount() -> [FishRarity: Int] {
    var counts: [FishRarity: Int] = [:]

    // Initialize all rarities with zero
    for rarity in FishRarity.allCases {
      counts[rarity] = 0
    }

    // Count fish by rarity
    for fish in statsManager.collectedFish {
      counts[fish.rarity, default: 0] += 1
    }

    return counts
  }

  // Helper function to get unique species count
  private func getUniqueSpeciesCount() -> Int {
    let uniqueSpecies = Set(statsManager.collectedFish.map { $0.fish.name })
    return uniqueSpecies.count
  }
}

// ShareSheet for iOS sharing
struct ShareSheet: UIViewControllerRepresentable {
  var activityItems: [Any]
  var applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: applicationActivities
    )
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
  ContentView()
}
