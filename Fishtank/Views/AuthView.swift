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
        .onTapGesture {
          dismissKeyboard()
        }

        // Main content - vertical layout only
        VStack(spacing: 30) {
          // App Logo/Title
          VStack(spacing: 16) {
            Image("Goldfish")
              .resizable()
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
              supabaseManager: supabaseManager
            )
            .padding(.horizontal, 30)
            .onTapGesture {
              dismissKeyboard()
            }

            // Continue as Guest Button (only show when not in username setup)
            Button(action: {
              supabaseManager.continueAsGuest()
            }) {
              HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                  .font(.caption)
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
            .padding(.top, 8)
          }

          Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
          dismissKeyboard()
        }
        .keyboardAdaptive()

        // Version display in bottom left corner
        VStack {
          Spacer()
          HStack {
            Text(AppConfig.versionAndBuild)
              .font(.system(.caption2, design: .monospaced))
              .foregroundColor(.white.opacity(0.5))
              .padding(.leading, 12)
              .padding(.bottom, 8)
            Spacer()
          }
        }
        .ignoresSafeArea(.keyboard)  // Ignore keyboard to stay fixed at bottom
      }
    }
    .navigationBarHidden(true)
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
}

#Preview {
  AuthView()
}
