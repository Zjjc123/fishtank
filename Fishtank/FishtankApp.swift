//
//  FishtankApp.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI
import BackgroundTasks
import Supabase

@main
struct FishtankApp: App {
  init() {
    // Initialize background tasks
    _ = BackgroundTaskManager.shared
  }
  
  var body: some Scene {
    WindowGroup {
      MainView()
        .onAppear {
          // Initialize InAppPurchaseManager and check for unfinished transactions
          Task {
            await InAppPurchaseManager.shared.checkForUnfinishedTransactions()
          }
        }
    }
  }
}
