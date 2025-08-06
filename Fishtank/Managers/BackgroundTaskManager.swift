import BackgroundTasks
import UIKit

@MainActor
final class BackgroundTaskManager {
  static let shared = BackgroundTaskManager()
  private let backgroundTaskIdentifier = "dev.jasonzhang.fishtank.session-completion"
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
  private let notificationManager = NotificationManager.shared

  private init() {
    registerBackgroundTasks()
  }

  func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) {
      [weak self] task in
      Task { @MainActor in
        await self?.handleAppRefresh(task: task as! BGAppRefreshTask)
      }
    }
  }

  func scheduleBackgroundTask(for completionTime: Date) {
    let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
    request.earliestBeginDate = completionTime

    do {
      try BGTaskScheduler.shared.submit(request)
      print("Background task scheduled for: \(completionTime)")
      
      // Also schedule a notification for the completion time
      if let commitment = CommitmentManager.shared.currentCommitment {
        notificationManager.scheduleCompletionNotification(for: commitment, at: completionTime)
        print("Completion notification scheduled for: \(completionTime)")
      }
    } catch {
      print("Could not schedule background task: \(error)")
    }
  }

  private func handleAppRefresh(task: BGAppRefreshTask) async {
    // Start background task to ensure we have enough time
    backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
      self?.endBackgroundTask()
      task.setTaskCompleted(success: false)
    }

    // Create a task assertion to prevent the system from prematurely ending the task
    task.expirationHandler = { [weak self] in
      Task { @MainActor in
        self?.endBackgroundTask()
        task.setTaskCompleted(success: false)
      }
    }

    // Check if there's an active commitment
    let commitmentManager = CommitmentManager.shared
    if commitmentManager.isActive, let commitment = commitmentManager.currentCommitment {
      // Get current time and calculate if commitment should be completed
      let now = Date()
      if let startTime = commitmentManager.commitmentStartTime {
        let elapsedSinceStart = now.timeIntervalSince(startTime)
        let shouldComplete = elapsedSinceStart >= commitment.duration
        
        if shouldComplete {
          // Mark the commitment as completed
          await completeCommitmentInBackground(commitment: commitment)
        } else {
          // Force an update of the progress
          commitmentManager.updateProgress()
          
          // Check again after updating progress
          if commitmentManager.progress >= 1.0 {
            await completeCommitmentInBackground(commitment: commitment)
          }
        }
      }
    }

    // Schedule next check if needed
    if let nextCompletionTime = CommitmentManager.shared.getNextCompletionTime() {
      scheduleBackgroundTask(for: nextCompletionTime)
    }

    // End background task and complete
    endBackgroundTask()
    task.setTaskCompleted(success: true)
  }
  
  private func completeCommitmentInBackground(commitment: FocusCommitment) async {
    // First stop app restrictions
    AppRestrictionManager.shared.stopAppRestriction()
    
    // Send an immediate notification
    notificationManager.sendImmediateNotification(
      title: "Focus Session Complete! 🎉",
      body: "\(commitment.rawValue) completed! You earned a \(commitment.lootboxType.rawValue) lootbox!"
    )
    
    // Track completed focus time
    await GameStateManager.shared.addFocusTime(commitment.duration)
    
    // Spawn lootbox reward (will be visible when app is opened)
    FishTankManager.shared.spawnLootbox(type: commitment.lootboxType)
    
    print("Successfully completed focus session in background")
    
    // Mark the commitment as completed in CommitmentManager
    // We need to do this in a way that preserves the completion state
    UserDefaults.standard.set(true, forKey: "pendingCommitmentCompletion")
    UserDefaults.standard.set(commitment.rawValue, forKey: "pendingCommitmentType")
    UserDefaults.standard.synchronize()
  }

  private func endBackgroundTask() {
    if backgroundTask != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }
  }
}
