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
  @Published var isGuest: Bool = false
  @Published var successMessage: String?
  @Published var needsUsernameSetup: Bool = false  // Add this property

  // User defaults keys
  private let guestModeKey = "isGuestMode"

  private init() {
    self.client = SupabaseClient(
      supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
      supabaseKey: SupabaseConfig.supabaseAnonKey
    )

    // Check if user previously selected guest mode
    if UserDefaults.standard.bool(forKey: guestModeKey) {
      self.isGuest = true
      self.isAuthenticated = true
    }

    // Check if user is already signed in
    Task {
      await checkCurrentUser()
    }
  }

  // Guest mode logic
  @MainActor
  func continueAsGuest() {
    self.isGuest = true
    self.currentUser = nil
    self.isAuthenticated = true  // For UI flow
    self.needsUsernameSetup = false  // Guests don't need username setup

    // Save guest mode preference
    UserDefaults.standard.set(true, forKey: guestModeKey)

    NotificationCenter.default.post(
      name: NSNotification.Name("SupabaseAuthStateChanged"),
      object: nil,
      userInfo: ["isAuthenticated": true, "isGuest": true, "needsUsernameSetup": false]
    )
  }

  @MainActor
  func exitGuestMode() {
    self.isGuest = false
    self.isAuthenticated = false

    // Clear guest mode preference
    UserDefaults.standard.set(false, forKey: guestModeKey)

    NotificationCenter.default.post(
      name: NSNotification.Name("SupabaseAuthStateChanged"),
      object: nil,
      userInfo: ["isAuthenticated": false, "isGuest": false]
    )
  }

  // MARK: - Authentication

  @MainActor
  func signUp(email: String, password: String, username: String? = nil) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      let response = try await client.auth.signUp(
        email: email,
        password: password
      )

      let user = response.user
      // Don't automatically authenticate user after sign up
      // They need to confirm their email first
      self.currentUser = User(
        id: user.id.uuidString,
        email: user.email ?? "",
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        emailConfirmed: false
      )
      self.isAuthenticated = false

      // If username is provided, update the user_profiles table
      if let username = username, !username.isEmpty {
        do {
          // Update the username in the user_profiles table
          _ = try await client.from("user_profiles")
            .update(["username": username])
            .eq("id", value: user.id.uuidString)
            .execute()
        } catch {
          print("Error updating username: \(error)")
          let errorString = error.localizedDescription.lowercased()

          // Check if the error is related to uniqueness constraint
          if errorString.contains("unique") || errorString.contains("duplicate") {
            errorMessage = "Username already taken. Please choose another username."

            // Clean up by signing out the user since we couldn't complete the full registration
            try? await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false

            isLoading = false
            return false
          }
          // Otherwise, don't fail the sign-up process if username update fails
        }
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
      // Check if email is confirmed
      let emailConfirmed = user.emailConfirmedAt != nil

      if !emailConfirmed {
        errorMessage = "Please check your email and confirm your account before signing in."
        isLoading = false
        return false
      }

      self.currentUser = User(
        id: user.id.uuidString,
        email: user.email ?? "",
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        emailConfirmed: emailConfirmed
      )

      // Check if user has a username BEFORE setting isAuthenticated
      let hasUsername = await checkIfUsernameExists()
      self.needsUsernameSetup = !hasUsername

      // Now set isAuthenticated
      self.isAuthenticated = true

      // Post notification about authentication state change with username info
      NotificationCenter.default.post(
        name: NSNotification.Name("SupabaseAuthStateChanged"),
        object: nil,
        userInfo: ["isAuthenticated": true, "needsUsernameSetup": !hasUsername]
      )

      // Trigger fish collection sync after successful sign in
      Task {
        await GameStateManager.shared.triggerSupabaseSync()
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
      self.needsUsernameSetup = false  // Reset the username setup flag

      // Clear guest mode preference
      UserDefaults.standard.set(false, forKey: guestModeKey)
      self.isGuest = false

      // Post notification about authentication state change
      NotificationCenter.default.post(
        name: NSNotification.Name("SupabaseAuthStateChanged"),
        object: nil,
        userInfo: ["isAuthenticated": false, "needsUsernameSetup": false]
      )
      // Clear all local fish data on logout
      GameStateManager.shared.clearLocalFishData()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  @MainActor
  func resendConfirmationEmail(email: String) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      try await client.auth.resend(
        email: email,
        type: .signup
      )
      isLoading = false
      return true
    } catch {
      let errorString = error.localizedDescription.lowercased()

      if errorString.contains("already") && errorString.contains("confirmed") {
        errorMessage = "This email is already confirmed."
      } else if errorString.contains("invalid") && errorString.contains("email") {
        errorMessage = "Please enter a valid email address."
      } else if errorString.contains("network") || errorString.contains("connection") {
        errorMessage = "Connection failed. Please check your internet and try again."
      } else {
        errorMessage = "Failed to resend confirmation email. Please try again."
      }
      isLoading = false
      return false
    }
  }

  @MainActor
  func verifyEmailWithOTP(email: String, token: String) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      // Call the Supabase API to verify the OTP token
      try await client.auth.verifyOTP(
        email: email,
        token: token,
        type: .signup
      )

      // After successful verification, check if the user is now authenticated
      if let session = try? await client.auth.session {
        let user = session.user
        let emailConfirmed = user.emailConfirmedAt != nil

        self.currentUser = User(
          id: user.id.uuidString,
          email: user.email ?? "",
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          emailConfirmed: emailConfirmed
        )

        // Check if user has a username BEFORE setting isAuthenticated
        let hasUsername = await checkIfUsernameExists()
        self.needsUsernameSetup = !hasUsername

        // Now set isAuthenticated
        self.isAuthenticated = true

        // Post notification about authentication state change with username info
        NotificationCenter.default.post(
          name: NSNotification.Name("SupabaseAuthStateChanged"),
          object: nil,
          userInfo: ["isAuthenticated": true, "needsUsernameSetup": !hasUsername]
        )

        // Trigger fish collection sync after successful sign in
        Task {
          await GameStateManager.shared.triggerSupabaseSync()
        }

        isLoading = false
        return true
      } else {
        errorMessage = "Failed to authenticate after verification. Please try signing in manually."
        isLoading = false
        return false
      }
    } catch {
      let errorString = error.localizedDescription.lowercased()

      if errorString.contains("invalid") && errorString.contains("token") {
        errorMessage = "Invalid verification code. Please try again."
      } else if errorString.contains("expired") {
        errorMessage = "Verification code has expired. Please request a new one."
      } else if errorString.contains("network") || errorString.contains("connection") {
        errorMessage = "Connection failed. Please check your internet and try again."
      } else {
        errorMessage = "Failed to verify your email. Please try again."
      }
      isLoading = false
      return false
    }
  }

  @MainActor
  func checkCurrentUser() async {
    do {
      let session = try await client.auth.session
      let user = session.user

      // Check if email is confirmed
      let emailConfirmed = user.emailConfirmedAt != nil

      if !emailConfirmed {
        // Sign out user if email is not confirmed
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
        self.needsUsernameSetup = false

        // Post notification about authentication state change
        NotificationCenter.default.post(
          name: NSNotification.Name("SupabaseAuthStateChanged"),
          object: nil,
          userInfo: ["isAuthenticated": false]
        )
        return
      }

      self.currentUser = User(
        id: user.id.uuidString,
        email: user.email ?? "",
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        emailConfirmed: emailConfirmed
      )

      // Check if user has a username BEFORE setting isAuthenticated
      let hasUsername = await checkIfUsernameExists()
      self.needsUsernameSetup = !hasUsername

      // Now set isAuthenticated
      self.isAuthenticated = true

      // Post notification about authentication state change with username info
      NotificationCenter.default.post(
        name: NSNotification.Name("SupabaseAuthStateChanged"),
        object: nil,
        userInfo: ["isAuthenticated": true, "needsUsernameSetup": !hasUsername]
      )

      // Trigger fish collection sync if user is authenticated
      Task {
        await GameStateManager.shared.triggerSupabaseSync()
      }
    } catch {
      // User is not signed in
      self.isAuthenticated = false
      self.needsUsernameSetup = false

      // Post notification about authentication state change
      NotificationCenter.default.post(
        name: NSNotification.Name("SupabaseAuthStateChanged"),
        object: nil,
        userInfo: ["isAuthenticated": false]
      )
    }
  }

  // MARK: - User Profile

  struct UserProfileInsert: Encodable {
    let id: String
    let total_focus_time: Double
    let total_fish_caught: Int
  }

  // New method to check if user has a username
  @MainActor
  func checkIfUsernameExists() async -> Bool {
    // Guests don't need usernames, so always return true for them
    guard let userId = currentUser?.id, !isGuest else { return true }

    do {
      let response = try await client.from("user_profiles")
        .select("username")
        .eq("id", value: userId)
        .single()
        .execute()

      print("🔍 checkIfUsernameExists: \(response)")

      // Properly decode the response
      struct UsernameResponse: Decodable {
        let username: String?
      }

      do {
        let usernameData = try JSONDecoder().decode(UsernameResponse.self, from: response.data)
        // Return true if username exists and is not empty
        return usernameData.username != nil && !usernameData.username!.isEmpty
      } catch {
        print("Error decoding username response: \(error)")
        return false
      }
    } catch {
      print("Failed to check username: \(error)")
      return false
    }
  }

  // New method to update username
  @MainActor
  func updateUsername(username: String) async -> Bool {
    guard let userId = currentUser?.id, !isGuest else { return false }
    errorMessage = nil
    isLoading = true

    do {
      // Validate username format
      let usernameRegex = "^[a-zA-Z0-9_]{5,20}$"
      let usernameTest = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
      guard usernameTest.evaluate(with: username) else {
        errorMessage =
          "Username must be 5-20 characters and contain only letters, numbers, and underscores."
        isLoading = false
        return false
      }

      // Update the username in the user_profiles table
      _ = try await client.from("user_profiles")
        .update(["username": username])
        .eq("id", value: userId)
        .execute()

      isLoading = false
      needsUsernameSetup = false
      return true
    } catch {
      let errorString = error.localizedDescription.lowercased()

      if errorString.contains("unique") || errorString.contains("duplicate") {
        errorMessage = "Username already taken. Please choose another username."
      } else {
        errorMessage = "Failed to update username. Please try again."
      }

      isLoading = false
      return false
    }
  }

  func getUserProfile() async -> UserProfile? {
    guard let userId = currentUser?.id, !isGuest else { return nil }

    do {
      let response = try await client.from("user_profiles")
        .select()
        .eq("id", value: userId)
        .single()
        .execute()

      let decoder = JSONDecoder()
      let dateFormatter = ISO8601DateFormatter()
      dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let date = dateFormatter.date(from: dateString) {
          return date
        }
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Invalid date format")
      }

      return try decoder.decode(UserProfile.self, from: response.data)
    } catch {
      print("Failed to get user profile: \(error)")
      return nil
    }
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
    guard let userId = currentUser?.id, !isGuest else { return }

    do {
      // Convert CollectedFish to database format
      let fishData = fish.map { f in
        FishInsert(
          id: f.id.uuidString,
          user_id: userId,
          fish_name: f.fish.name,
          fish_image_name: f.fish.imageName,
          fish_rarity: f.rarity.rawValue,
          fish_size: f.fish.size.rawValue,
          custom_name: f.name,
          date_caught: ISO8601DateFormatter().string(from: f.dateCaught),
          is_visible: f.isVisible,
          is_shiny: f.isShiny
        )
      }

      // Delete all existing fish for this user
      _ = try await client.from("user_fish")
        .delete()
        .eq("user_id", value: userId)
        .execute()

      // Insert all fish
      _ = try await client.from("user_fish")
        .insert(fishData)
        .execute()
    } catch {
      print("Error saving fish to Supabase: \(error)")
    }
  }

  // Add 'throws' to propagate errors
  func saveFishToSupabase(_ fish: CollectedFish) async throws {
    guard let userId = currentUser?.id, !isGuest else { return }
    do {
      let fishData = FishInsert(
        id: fish.id.uuidString,
        user_id: userId,
        fish_name: fish.fish.name,
        fish_image_name: fish.fish.imageName,
        fish_rarity: fish.rarity.rawValue,
        fish_size: fish.fish.size.rawValue,
        custom_name: fish.name,
        date_caught: ISO8601DateFormatter().string(from: fish.dateCaught),
        is_visible: fish.isVisible,
        is_shiny: fish.isShiny
      )
      // Insert the fish
      _ = try await client.from("user_fish")
        .insert(fishData)
        .execute()
      print("✅ Saved fish to Supabase: \(fish.name)")
    } catch {
      print("❌ Error saving fish to Supabase: \(error)")
      throw error
    }
  }

  // Add 'throws' to propagate errors
  func saveFishesToSupabase(_ fishes: [CollectedFish]) async throws {
    guard let userId = currentUser?.id, !isGuest else { return }
    do {
      let fishData = fishes.map { f in
        FishInsert(
          id: f.id.uuidString,
          user_id: userId,
          fish_name: f.fish.name,
          fish_image_name: f.fish.imageName,
          fish_rarity: f.rarity.rawValue,
          fish_size: f.fish.size.rawValue,
          custom_name: f.name,
          date_caught: ISO8601DateFormatter().string(from: f.dateCaught),
          is_visible: f.isVisible,
          is_shiny: f.isShiny
        )
      }
      _ = try await client.from("user_fish")
        .insert(fishData)
        .execute()
      print("✅ Saved \(fishes.count) fishes to Supabase")
    } catch {
      print("❌ Error saving fishes to Supabase: \(error)")
      throw error
    }
  }

  // Delete a fish from Supabase
  func deleteFishFromSupabase(_ fishId: UUID) async {
    guard let userId = currentUser?.id, !isGuest else { return }

    do {
      _ = try await client.from("user_fish")
        .delete()
        .eq("id", value: fishId.uuidString)
        .eq("user_id", value: userId)
        .execute()
    } catch {
      print("Error deleting fish from Supabase: \(error)")
    }
  }

  // Delete multiple fish from Supabase
  func deleteAllFishFromSupabase(_ fishIds: [UUID]) async {
    guard let userId = currentUser?.id, !isGuest else { return }

    do {
      // Delete all specified fish IDs
      for fishId in fishIds {
        _ = try await client.from("user_fish")
          .delete()
          .eq("id", value: fishId.uuidString)
          .eq("user_id", value: userId)
          .execute()
      }
    } catch {
      print("Error deleting fish from Supabase: \(error)")
    }
  }

  // Update fish visibility in Supabase
  func updateFishVisibilityInSupabase(_ fishId: UUID, isVisible: Bool) async {
    guard let userId = currentUser?.id, !isGuest else { return }

    do {
      _ = try await client.from("user_fish")
        .update(["is_visible": isVisible])
        .eq("id", value: fishId.uuidString)
        .eq("user_id", value: userId)
        .execute()
    } catch {
      print("Error updating fish visibility in Supabase: \(error)")
    }
  }

  // Update fish name in Supabase
  func updateFishNameInSupabase(_ fishId: UUID, customName: String) async {
    guard let userId = currentUser?.id, !isGuest else { return }

    do {
      _ = try await client.from("user_fish")
        .update(["custom_name": customName])
        .eq("id", value: fishId.uuidString)
        .eq("user_id", value: userId)
        .execute()
    } catch {
      print("Error updating fish name in Supabase: \(error)")
    }
  }

  func loadFishCollection() async -> [CollectedFish] {
    guard let userId = currentUser?.id, !isGuest else { return [] }

    do {
      print("🔍 loadFishCollection: Fetching fish for user \(userId)")

      // Fetch all fish for this user
      let response = try await client.from("user_fish")
        .select()
        .eq("user_id", value: userId)
        .execute()

      print("📊 Response: \(response)")
      print("📊 Response type: \(type(of: response))")
      print(
        "📊 Response properties - data: \(response.data.isEmpty ? "empty" : "has data"), count: \(response.count ?? 0)"
      )

      let data = response.data
      print("📦 Raw data size: \(data.count) bytes")

      if let jsonString = String(data: data, encoding: .utf8) {
        print("📝 JSON data: \(jsonString)")
      }

      // Parse the response
      struct FishResponse: Decodable {
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

        enum CodingKeys: String, CodingKey {
          case id
          case user_id
          case fish_name
          case fish_image_name
          case fish_rarity
          case fish_size
          case custom_name
          case date_caught
          case is_visible
          case is_shiny
        }
      }

      // Try to decode the response data directly
      do {
        let fishObjects = try JSONDecoder().decode([FishResponse].self, from: data)
        print("🐠 loadFishCollection: Decoded \(fishObjects.count) fish objects")

        // Convert to CollectedFish objects
        return fishObjects.compactMap { f in
          guard
            let id = UUID(uuidString: f.id),
            let rarity = FishRarity(rawValue: f.fish_rarity),
            let size = FishSize(rawValue: f.fish_size),
            let dateCaught = ISO8601DateFormatter().date(from: f.date_caught)
          else {
            print("❌ Failed to parse fish: \(f.id)")
            return nil
          }

          let fish = Fish(
            name: f.fish_name,
            imageName: f.fish_image_name,
            rarity: rarity,
            size: size
          )

          return CollectedFish(
            id: id,
            fish: fish,
            name: f.custom_name,
            dateCaught: dateCaught,
            isVisible: f.is_visible,
            isShiny: f.is_shiny
          )
        }
      } catch {
        print("❌ JSON decoding error: \(error)")

        // Alternative approach: try using JSONSerialization
        do {
          if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            print("🔄 Falling back to JSONSerialization - found \(jsonArray.count) items")

            return jsonArray.compactMap { dict -> CollectedFish? in
              guard
                let idString = dict["id"] as? String,
                let id = UUID(uuidString: idString),
                let fishName = dict["fish_name"] as? String,
                let fishImageName = dict["fish_image_name"] as? String,
                let fishRarityString = dict["fish_rarity"] as? String,
                let fishRarity = FishRarity(rawValue: fishRarityString),
                let fishSizeString = dict["fish_size"] as? String,
                let fishSize = FishSize(rawValue: fishSizeString),
                let customName = dict["custom_name"] as? String,
                let dateCaughtString = dict["date_caught"] as? String,
                let dateCaught = ISO8601DateFormatter().date(from: dateCaughtString),
                let isVisible = dict["is_visible"] as? Bool,
                let isShiny = dict["is_shiny"] as? Bool
              else {
                print("❌ Failed to parse fish dictionary")
                return nil
              }

              let fish = Fish(
                name: fishName,
                imageName: fishImageName,
                rarity: fishRarity,
                size: fishSize
              )

              return CollectedFish(
                id: id,
                fish: fish,
                name: customName,
                dateCaught: dateCaught,
                isVisible: isVisible,
                isShiny: isShiny
              )
            }
          } else {
            print("❌ JSONSerialization failed - could not cast to [[String: Any]]")
            return []
          }
        } catch {
          print("❌ JSONSerialization error: \(error)")
          return []
        }
      }
    } catch {
      print("❌ Error loading fish from Supabase: \(error)")
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
