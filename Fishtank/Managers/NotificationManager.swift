import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        // Request notification authorization when the manager is initialized
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else if let error = error {
                print("Notification authorization failed: \(error)")
            }
        }
    }
    
    func scheduleCompletionNotification(for commitment: FocusCommitment, at completionTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete! 🎉"
        content.body = "\(commitment.rawValue) completed! You've earned a \(commitment.lootboxType.emoji) \(commitment.lootboxType.rawValue) lootbox!"
        content.sound = .default
        
        // Create a calendar trigger for the exact completion time
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: completionTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "focus-completion-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 