//
//  FishtankApp.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

@main
struct FishtankApp: App {
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
