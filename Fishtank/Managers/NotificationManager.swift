import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        // Request notification authorization when the manager is initialized
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
        content.body = "\(commitment.rawValue) completed! You earned a \(commitment.lootboxType.rawValue) lootbox!"
        content.sound = .default
        
        // Create a calendar trigger
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: completionTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "commitment-completion-\(completionTime.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Successfully scheduled completion notification for: \(completionTime)")
            }
        }
    }
    
    func sendImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Create an immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the request with a unique identifier
        let request = UNNotificationRequest(
            identifier: "immediate-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Send the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending immediate notification: \(error)")
            } else {
                print("Successfully sent immediate notification")
            }
        }
    }
    
    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cancelled all pending notifications")
    }
} 