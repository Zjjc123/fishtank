//
//  SupabaseManager.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation
import Supabase

class SupabaseManager: ObservableObject {
  static let shared = SupabaseManager()

  private let client: SupabaseClient

  @Published var currentUser: User?
  @Published var isAuthenticated = false
  @Published var isLoading = false
  @Published var errorMessage: String?

  private init() {
    self.client = SupabaseClient(
      supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
      supabaseKey: SupabaseConfig.supabaseAnonKey
    )

    // Check if user is already signed in
    Task {
      await checkCurrentUser()
    }
  }

  // MARK: - Authentication

  @MainActor
  func signUp(email: String, password: String) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      let response = try await client.auth.signUp(
        email: email,
        password: password
      )

      let user = response.user
      self.currentUser = User(
        id: user.id.uuidString,
        email: user.email ?? "",
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      )
      self.isAuthenticated = true

      // Trigger fish collection sync after successful sign up
      Task {
        await GameStatsManager.shared.triggerSupabaseSync()
      }

      isLoading = false
      return true
    } catch {
      // Provide more user-friendly error messages
      let errorString = error.localizedDescription.lowercased()
      
      if errorString.contains("invalid") && errorString.contains("credentials") {
        errorMessage = "Invalid email or password. Please try again."
      } else if errorString.contains("email") && errorString.contains("confirmed") {
        errorMessage = "Please check your email and confirm your account."
      } else if errorString.contains("weak") && errorString.contains("password") {
        errorMessage = "Password is too weak. Please use at least 6 characters."
      } else if errorString.contains("already") && errorString.contains("use") {
        errorMessage = "An account with this email already exists."
      } else if errorString.contains("invalid") && errorString.contains("email") {
        errorMessage = "Please enter a valid email address."
      } else if errorString.contains("network") || errorString.contains("connection") {
        errorMessage = "Connection failed. Please check your internet and try again."
      } else {
        errorMessage = "Authentication failed. Please try again."
      }
      isLoading = false
      return false
    }
  }

  @MainActor
  func signIn(email: String, password: String) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      let response = try await client.auth.signIn(
        email: email,
        password: password
      )

      let user = response.user
      self.currentUser = User(
        id: user.id.uuidString,
        email: user.email ?? "",
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      )
      self.isAuthenticated = true
      
      // Trigger fish collection sync after successful sign in
      Task {
        await GameStatsManager.shared.triggerSupabaseSync()
      }
      
      isLoading = false
      return true
    } catch {
      // Provide more user-friendly error messages
      let errorString = error.localizedDescription.lowercased()
      
      if errorString.contains("invalid") && errorString.contains("credentials") {
        errorMessage = "Invalid email or password. Please try again."
      } else if errorString.contains("email") && errorString.contains("confirmed") {
        errorMessage = "Please check your email and confirm your account."
      } else if errorString.contains("weak") && errorString.contains("password") {
        errorMessage = "Password is too weak. Please use at least 6 characters."
      } else if errorString.contains("already") && errorString.contains("use") {
        errorMessage = "An account with this email already exists."
      } else if errorString.contains("invalid") && errorString.contains("email") {
        errorMessage = "Please enter a valid email address."
      } else if errorString.contains("network") || errorString.contains("connection") {
        errorMessage = "Connection failed. Please check your internet and try again."
      } else {
        errorMessage = "Authentication failed. Please try again."
      }
      isLoading = false
      return false
    }
  }

  @MainActor
  func signOut() async {
    do {
      try await client.auth.signOut()
      self.currentUser = nil
      self.isAuthenticated = false
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  @MainActor
  func checkCurrentUser() async {
    do {
      let session = try await client.auth.session
      let user = session.user
      self.currentUser = User(
        id: user.id.uuidString,
        email: user.email ?? "",
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      )
      self.isAuthenticated = true
      
      // Trigger fish collection sync if user is authenticated
      Task {
        await GameStatsManager.shared.triggerSupabaseSync()
      }
    } catch {
      // User is not signed in
      self.isAuthenticated = false
    }
  }

  // MARK: - User Profile

  struct UserProfileInsert: Encodable {
    let id: String
    let email: String
    let total_focus_time: Double
    let total_fish_caught: Int
  }

  // MARK: - Fish Database Operations

  struct FishInsert: Encodable {
    let id: String
    let user_id: String
    let fish_name: String
    let fish_image_name: String
    let fish_rarity: String
    let fish_size: String
    let custom_name: String
    let date_caught: String
    let is_visible: Bool
    let is_shiny: Bool
  }

  func saveFishCollection(_ fish: [CollectedFish]) async {
    guard let userId = currentUser?.id else { return }

    do {
      // Convert CollectedFish to database format
      let fishData = fish.map { f in
        FishInsert(
          id: f.id.uuidString,
          user_id: userId,
          fish_name: f.fish.name,
          fish_image_name: f.fish.imageName,
          fish_rarity: f.fish.rarity.rawValue,
          fish_size: f.fish.size.rawValue,
          custom_name: f.name,
          date_caught: ISO8601DateFormatter().string(from: f.dateCaught),
          is_visible: f.isVisible,
          is_shiny: f.isShiny
        )
      }

      // Delete existing fish for this user
      _ = try await client.from("user_fish").delete().eq("user_id", value: userId).execute()

      // Insert new fish collection
      if !fishData.isEmpty {
        _ = try await client.from("user_fish").insert(fishData).execute()
      }
    } catch {
      print("Failed to save fish collection: \(error)")
    }
  }

  func loadFishCollection() async -> [CollectedFish] {
    guard let userId = currentUser?.id else { return [] }

    do {
      let response =
        try await client.from("user_fish").select().eq("user_id", value: userId).execute().value
        as [FishRecord]
      return response.compactMap { record in
        guard let fishRarity = FishRarity(rawValue: record.fishRarity),
          let fishSize = FishSize(rawValue: record.fishSize),
          let dateCaught = ISO8601DateFormatter().date(from: record.dateCaught),
          let id = UUID(uuidString: record.id)
        else {
          return nil
        }

        let fish = Fish(
          name: record.fishName,
          imageName: record.fishImageName,
          rarity: fishRarity,
          size: fishSize
        )

        let collectedFish = CollectedFish(
          id: id,
          fish: fish,
          name: record.customName,
          dateCaught: dateCaught,
          isVisible: record.isVisible,
          isShiny: record.isShiny
        )

        return collectedFish
      }
    } catch {
      print("Failed to load fish collection: \(error)")
      return []
    }
  }

  struct UserStatsUpdate: Encodable {
    let total_focus_time: Double
    let total_fish_caught: Int
  }

  func updateUserStats(totalFocusTime: TimeInterval, totalFishCaught: Int) async {
    guard let userId = currentUser?.id else { return }

    do {
      let stats = UserStatsUpdate(
        total_focus_time: totalFocusTime,
        total_fish_caught: totalFishCaught
      )
      _ = try await client.from("user_profiles").update(stats).eq("id", value: userId).execute()
    } catch {
      print("Failed to update user stats: \(error)")
    }
  }
}

// MARK: - Database Models

struct FishRecord: Codable {
  let id: String
  let userId: String
  let fishName: String
  let fishImageName: String
  let fishRarity: String
  let fishSize: String
  let customName: String
  let dateCaught: String
  let isVisible: Bool
  let isShiny: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case fishName = "fish_name"
    case fishImageName = "fish_image_name"
    case fishRarity = "fish_rarity"
    case fishSize = "fish_size"
    case customName = "custom_name"
    case dateCaught = "date_caught"
    case isVisible = "is_visible"
    case isShiny = "is_shiny"
  }
}
