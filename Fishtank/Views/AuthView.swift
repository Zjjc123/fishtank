//
//  AuthView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI
import UIKit

struct AuthView: View {
  @StateObject private var supabaseManager = SupabaseManager.shared
  @State private var email = ""
  @State private var password = ""
  @State private var confirmPassword = ""
  @State private var isSignUp = false
  @State private var showPassword = false
  @State private var showConfirmationMessage = false
  @State private var showUsernameSetup = false  // This will now be controlled by supabaseManager.needsUsernameSetup
  @State private var showPasswordReset = false  // Add this state variable
  @State private var isGuestLoading = false  // Track guest mode loading state
  @State private var isCheckingAuth = true  // Track initial auth check state
  @AppStorage("shouldShowAuthView") private var shouldShowAuthView = false
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background gradient
        LinearGradient(
          colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.7)],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()
        
        if isCheckingAuth {
          // Show only a centered loading indicator during initial auth check
          VStack(spacing: 16) {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .scaleEffect(1.5)
          }
        } else {
          // Main content - only show after auth check completes
          VStack(spacing: 30) {
            // App Logo/Title
            VStack(spacing: 16) {
              Image("Goldfish")
                .resizable()
                .interpolation(.none)  // Disable antialiasing
                .scaledToFit()
                .frame(width: 80, height: 80)

              Text("Fishtank")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)

              Text("Focus and collect fish")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 60)
            .onTapGesture {
              dismissKeyboard()
            }

            // Show Username Setup if needed, otherwise show Auth Form
            if supabaseManager.needsUsernameSetup {
              UsernameSetupView(
                showUsernameSetup: $showUsernameSetup,
                shouldShowAuthView: $shouldShowAuthView,
                supabaseManager: supabaseManager
              )
              .padding(.horizontal, 30)
            } else {
              // Auth Form
              AuthFormView(
                email: $email,
                password: $password,
                confirmPassword: $confirmPassword,
                isSignUp: $isSignUp,
                showPassword: $showPassword,
                showConfirmationMessage: $showConfirmationMessage,
                showUsernameSetup: $showUsernameSetup,
                shouldShowAuthView: $shouldShowAuthView,
                supabaseManager: supabaseManager,
                showPasswordReset: $showPasswordReset
              )
              .padding(.horizontal, 30)
              .onTapGesture {
                dismissKeyboard()
              }

              // Continue as Guest Button (only show when not in username setup)
              Button(action: {
                isGuestLoading = true
                // Use slight delay to ensure the loading state is visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  supabaseManager.continueAsGuest()
                  // Reset loading state after a short delay to ensure animation completes
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isGuestLoading = false
                  }
                }
              }) {
                HStack(spacing: 6) {
                  if isGuestLoading {
                    ProgressView()
                      .progressViewStyle(CircularProgressViewStyle(tint: .white))
                      .scaleEffect(0.7)
                  } else {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                      .font(.caption)
                  }
                  Text("Continue as Guest")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                  Capsule()
                    .fill(Color.gray.opacity(0.2))
                )
              }
              .disabled(supabaseManager.isLoading || isGuestLoading)
              .opacity((supabaseManager.isLoading || isGuestLoading) ? 0.5 : 1)
              .padding(.top, 8)
            }

            Spacer()
            
            // Version display at bottom
            HStack {
              Text(AppConfig.versionAndBuild)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 12)
                .padding(.bottom, 8)
              Spacer()
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            dismissKeyboard()
          }
          .keyboardAdaptive()
          
          // Loading overlay for explicit auth operations (not initial check)
          if supabaseManager.isLoading {
            ZStack {
              Color.black.opacity(0.4)
                .ignoresSafeArea()
              
              VStack(spacing: 16) {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  .scaleEffect(1.5)
                
                Text("Loading...")
                  .font(.system(.body, design: .rounded))
                  .fontWeight(.medium)
                  .foregroundColor(.white)
              }
              .padding(24)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.black.opacity(0.6))
              )
            }
            .transition(.opacity)
          }
        }
      }
    }
    .navigationBarHidden(true)
    .fullScreenCover(
      isPresented: $showPasswordReset,
      content: {
        PasswordResetView(initialEmail: email)
          .transition(.identity)  // Remove transition animation
      }
    )
    .animation(.easeInOut(duration: 0.2), value: supabaseManager.isLoading)
    .animation(.easeInOut(duration: 0.2), value: isGuestLoading)
    .animation(.easeInOut(duration: 0.2), value: isCheckingAuth)
    .animation(nil, value: showPasswordReset)  // Disable animation for the state change
    .onAppear {
      // Set portrait orientation using the recommended API
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
          interfaceOrientations: .portrait)
        windowScene.requestGeometryUpdate(geometryPreferences)
      }

      // Set app orientation mask
      AppDelegate.orientationLock = .portrait
      if #available(iOS 16.0, *) {
        UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .forEach {
            $0.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
          }
      } else {
        UIViewController.attemptRotationToDeviceOrientation()
      }

      // If coming from guest mode, default to sign up mode
      if shouldShowAuthView {
        isSignUp = true
      }

      // Immediately set showUsernameSetup if needed
      showUsernameSetup = supabaseManager.needsUsernameSetup
      
      // Check authentication status
      Task {
        await supabaseManager.checkCurrentUser()
        // Delay for at least a short time to avoid flickering
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await MainActor.run {
          isCheckingAuth = false
        }
      }
    }
    .onDisappear {
      // Clear success messages when the view disappears
      supabaseManager.successMessage = nil
    }
    // Listen for changes to needsUsernameSetup
    .onChange(of: supabaseManager.needsUsernameSetup) { needsSetup in
      showUsernameSetup = needsSetup
    }
  }

  func dismissKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

#Preview {
  AuthView()
}
