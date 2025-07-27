//
//  UsernameSetupView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Username Setup View
struct UsernameSetupView: View {
  @Binding var showUsernameSetup: Bool
  @Binding var shouldShowAuthView: Bool
  let supabaseManager: SupabaseManager
  @State private var username: String = ""

  // Extract common styles to reduce complexity
  private func textFieldBackground() -> some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color.white.opacity(0.15))
  }

  private func textFieldBorder() -> some View {
    RoundedRectangle(cornerRadius: 8)
      .stroke(Color.white.opacity(0.2), lineWidth: 1)
  }

  var body: some View {
    VStack(spacing: 16) {
      // Header
      HStack(spacing: 6) {
        Image(systemName: "person.text.rectangle.fill")
          .font(.caption)
          .foregroundColor(.white.opacity(0.9))

        Text("Create Username")
          .font(.system(.caption, design: .rounded))
          .fontWeight(.semibold)
          .foregroundColor(.white)
      }

      // Welcome message
      Text("Welcome! Before you start, please create a username for your account.")
        .font(.system(.caption, design: .rounded))
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)

      // Username Field
      VStack(alignment: .leading, spacing: 4) {
        Text("Username")
          .font(.system(.caption2, design: .rounded))
          .foregroundColor(.white.opacity(0.7))

        TextField("Enter your username", text: $username)
          .font(.system(.callout, design: .rounded))
          .padding(8)
          .frame(height: 36)
          .background(textFieldBackground())
          .overlay(textFieldBorder())
          .foregroundColor(.white)
          .autocapitalization(.none)
          .disableAutocorrection(true)

        // Username requirements helper text
        Text("5-20 characters, letters, numbers, and underscores only")
          .font(.system(.caption2, design: .rounded))
          .foregroundColor(.white.opacity(0.6))
          .padding(.top, 2)
      }
      .padding(.vertical, 8)

      // Error Message
      if let errorMessage = supabaseManager.errorMessage {
        errorView(message: errorMessage)
      }

      // Success Message
      if let successMessage = supabaseManager.successMessage {
        successView(message: successMessage)
      }

      // Create Username Button
      Button(action: {
        Task {
          // Convert username to lowercase before submitting
          let lowercasedUsername = username.lowercased()
          let success = await supabaseManager.updateUsername(username: lowercasedUsername)
          if success {
            // Username created successfully
            shouldShowAuthView = false  // This will trigger MainView to show ContentView
            showUsernameSetup = false
            supabaseManager.needsUsernameSetup = false

            // Post notification to ensure MainView updates
            NotificationCenter.default.post(
              name: NSNotification.Name("SupabaseAuthStateChanged"),
              object: nil,
              userInfo: ["isAuthenticated": true, "needsUsernameSetup": false]
            )
          }
        }
      }) {
        HStack(spacing: 6) {
          if supabaseManager.isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .scaleEffect(0.7)
          } else {
            Image(systemName: "checkmark.circle.fill")
              .font(.caption)
          }

          Text("Create Username")
            .font(.system(.caption, design: .rounded))
            .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue.opacity(0.6))
            .overlay(
              RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        )
      }
      .disabled(supabaseManager.isLoading || !isValidUsername)
      .opacity((supabaseManager.isLoading || !isValidUsername) ? 0.5 : 1)

      // Sign out button
      Button(action: {
        Task {
          await supabaseManager.signOut()
          await MainActor.run {
            // Reset UI state
            showUsernameSetup = false
            shouldShowAuthView = true

            // Post notification to ensure MainView updates
            NotificationCenter.default.post(
              name: NSNotification.Name("SupabaseAuthStateChanged"),
              object: nil,
              userInfo: ["isAuthenticated": false]
            )
          }
        }
      }) {
        HStack(spacing: 4) {
          Image(systemName: "arrow.backward.circle.fill")
            .font(.caption2)
          Text("Sign Out")
            .font(.system(.caption2, design: .rounded))
            .fontWeight(.medium)
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
          Capsule()
            .fill(Color.gray.opacity(0.2))
            .overlay(
              Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        )
      }
      .padding(.top, 8)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    )
    .frame(maxWidth: 400)
  }

  private var isValidUsername: Bool {
    // Username validation: 5-20 chars, alphanumeric + underscores only
    return username.count >= 5 && username.count <= 20
      && username.range(of: "^[a-zA-Z0-9_]+$", options: .regularExpression) != nil
  }

  @ViewBuilder
  private func errorView(message: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.caption2)
        .foregroundColor(.red)

      Text(message)
        .font(.system(.caption2, design: .rounded))
        .foregroundColor(.red)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      Button(action: {
        supabaseManager.errorMessage = nil
      }) {
        Image(systemName: "xmark.circle.fill")
          .font(.caption2)
          .foregroundColor(.red.opacity(0.7))
      }
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.red.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    )
    .transition(.opacity.combined(with: .scale))
  }

  @ViewBuilder
  private func successView(message: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "checkmark.circle.fill")
        .font(.caption2)
        .foregroundColor(.green)

      Text(message)
        .font(.system(.caption2, design: .rounded))
        .foregroundColor(.green)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      Button(action: {
        supabaseManager.successMessage = nil
      }) {
        Image(systemName: "xmark.circle.fill")
          .font(.caption2)
          .foregroundColor(.green.opacity(0.7))
      }
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.green.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    )
    .transition(.opacity.combined(with: .scale))
  }
}
