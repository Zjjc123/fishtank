//
//  FishtankApp.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI
import BackgroundTasks
import Supabase
import os.log

@main
struct FishtankApp: App {
  @StateObject private var supabaseManager = SupabaseManager.shared
  
  init() {
    // Initialize background tasks
    _ = BackgroundTaskManager.shared
    
    // Enable debug logging for Supabase
    // Note: The Supabase Swift client doesn't have a direct logger property
    // Instead, we'll use OS logging for our own Supabase-related logs
    let supabaseLogger = Logger(subsystem: "com.fishtank.app", category: "supabase")
    supabaseLogger.info("Initializing Supabase integration")
    
    // Configure app for Supabase as source of truth
    configureAppForSupabase()
  }
  
  private func configureAppForSupabase() {
    // Set up notification observers for authentication state changes
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name("SupabaseAuthStateChanged"),
      object: nil,
      queue: .main
    ) { notification in
      if let isAuthenticated = notification.userInfo?["isAuthenticated"] as? Bool {
        print("Auth state changed: \(isAuthenticated ? "Authenticated" : "Not authenticated")")
        
        // Trigger data refresh when authentication state changes
        if isAuthenticated {
          Task {
            await GameStatsManager.shared.triggerSupabaseSync()
          }
        }
      }
    }
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
        .onOpenURL { url in
          handleDeepLink(url)
        }
    }
  }
  
  // Handle deep links from email confirmation
  private func handleDeepLink(_ url: URL) {
    print("Received deep link: \(url)")
    
    // Check if this is a login callback
    if url.scheme == "fishtank" && url.host == "login-callback" {
      // Extract access token and refresh token if available
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
         let queryItems = components.queryItems {
        
        // Look for access_token and refresh_token
        let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value
        let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value
        
        if let accessToken = accessToken {
          print("Found access token in deep link")
          
          // Process the token and authenticate the user
          Task {
            await supabaseManager.handleDeepLinkAuthentication(accessToken: accessToken, refreshToken: refreshToken)
          }
        }
      }
    }
  }
}
