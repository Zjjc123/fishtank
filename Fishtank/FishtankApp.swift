//
//  FishtankApp.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI
import BackgroundTasks

@main
struct FishtankApp: App {
  init() {
    // Initialize background tasks
    _ = BackgroundTaskManager.shared
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          // Initialize InAppPurchaseManager and check for unfinished transactions
          Task {
            await InAppPurchaseManager.shared.checkForUnfinishedTransactions()
          }
        }
    }
  }
}
