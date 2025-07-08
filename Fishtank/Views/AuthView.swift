//
//  AuthView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct AuthView: View {
  @StateObject private var supabaseManager = SupabaseManager.shared
  @State private var email = ""
  @State private var password = ""
  @State private var confirmPassword = ""
  @State private var isSignUp = false
  @State private var showPassword = false
  @State private var showConfirmationMessage = false

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

        // Animated bubbles
        ForEach(0..<20, id: \.self) { _ in
          Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: CGFloat.random(in: 10...30))
            .position(
              x: CGFloat.random(in: 0...geometry.size.width),
              y: CGFloat.random(in: 0...geometry.size.height)
            )
            .animation(
              Animation.linear(duration: Double.random(in: 3...8))
                .repeatForever(autoreverses: false),
              value: UUID()
            )
        }

        // Main content - responsive layout
        if geometry.size.width > geometry.size.height {
          // Horizontal layout
          HStack(spacing: 40) {
            // Left side - Logo and branding
            VStack(spacing: 24) {
              Spacer()

              VStack(spacing: 20) {
                Image(systemName: "fish.fill")
                  .font(.system(size: 72))
                  .foregroundColor(.white)

                VStack(spacing: 8) {
                  Text("Fishtank")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                  Text("Focus and collect fish")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                }
              }

              Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right side - Auth form
            VStack(spacing: 24) {
              Spacer()

              AuthFormView(
                email: $email,
                password: $password,
                confirmPassword: $confirmPassword,
                isSignUp: $isSignUp,
                showPassword: $showPassword,
                showConfirmationMessage: $showConfirmationMessage,
                supabaseManager: supabaseManager
              )

              Spacer()
            }
            .frame(maxWidth: .infinity)
          }
          .padding(.horizontal, 60)
        } else {
          // Vertical layout (original)
          VStack(spacing: 30) {
            // App Logo/Title
            VStack(spacing: 16) {
              Image(systemName: "fish.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)

              Text("Fishtank")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)

              Text("Focus and collect fish")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 60)

            // Auth Form
            AuthFormView(
              email: $email,
              password: $password,
              confirmPassword: $confirmPassword,
              isSignUp: $isSignUp,
              showPassword: $showPassword,
              showConfirmationMessage: $showConfirmationMessage,
              supabaseManager: supabaseManager
            )
            .padding(.horizontal, 30)

            Spacer()
          }
        }
      }
    }
    .navigationBarHidden(true)
  }
}

// MARK: - Auth Form View
struct AuthFormView: View {
  @Binding var email: String
  @Binding var password: String
  @Binding var confirmPassword: String
  @Binding var isSignUp: Bool
  @Binding var showPassword: Bool
  @Binding var showConfirmationMessage: Bool
  let supabaseManager: SupabaseManager

  // MARK: - Computed Properties
  private var resendButtonStyle: some View {
    RoundedRectangle(cornerRadius: 6)
      .fill(Color.blue.opacity(0.1))
  }

  private var backButtonStyle: some View {
    RoundedRectangle(cornerRadius: 6)
      .fill(.ultraThinMaterial)
  }

  private var confirmationBackgroundStyle: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color.green.opacity(0.1))
  }

  var body: some View {
    VStack(spacing: 16) {
      // Header
      HStack(spacing: 6) {
        Image(systemName: "person.circle.fill")
          .font(.caption)
          .foregroundColor(.white.opacity(0.9))

        Text(isSignUp ? "Create Account" : "Sign In")
          .font(.system(.caption, design: .rounded))
          .fontWeight(.semibold)
          .foregroundColor(.white)
      }

      // Form fields
      if !showConfirmationMessage {
        VStack(spacing: 12) {
          // Email Field
          VStack(alignment: .leading, spacing: 4) {
            Text("Email")
              .font(.system(.caption2, design: .rounded))
              .foregroundColor(.white.opacity(0.7))

            TextField("Enter your email", text: $email)
              .font(.system(.callout, design: .rounded))
              .padding(8)
              .frame(height: 36)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.white.opacity(0.15))
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
              .foregroundColor(.white)
              .keyboardType(.emailAddress)
              .autocapitalization(.none)
              .disableAutocorrection(true)
          }

          // Password Field
          VStack(alignment: .leading, spacing: 4) {
            Text("Password")
              .font(.system(.caption2, design: .rounded))
              .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 6) {
              if showPassword {
                TextField("Enter your password", text: $password)
                  .font(.system(.callout, design: .rounded))
              } else {
                SecureField("Enter your password", text: $password)
                  .font(.system(.callout, design: .rounded))
              }

              Button(action: {
                showPassword.toggle()
              }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                  .font(.caption2)
                  .foregroundColor(.white.opacity(0.7))
                  .frame(width: 28, height: 28)
                  .background(
                    RoundedRectangle(cornerRadius: 6)
                      .fill(.ultraThinMaterial)
                  )
              }
            }
            .padding(8)
            .frame(height: 36)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.15))
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            )
            .foregroundColor(.white)
          }

          // Confirm Password Field (only for sign up)
          if isSignUp {
            VStack(alignment: .leading, spacing: 4) {
              Text("Confirm Password")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

              SecureField("Confirm your password", text: $confirmPassword)
                .font(.system(.callout, design: .rounded))
                .padding(8)
                .frame(height: 36)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                      RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                )
                .foregroundColor(.white)
            }
          }
        }
      }

      // Confirmation Message
      if showConfirmationMessage {
        VStack(spacing: 12) {
          HStack(spacing: 6) {
            Image(systemName: "envelope.fill")
              .font(.caption2)
              .foregroundColor(.green)

            Text("Check your email!")
              .font(.system(.caption2, design: .rounded))
              .fontWeight(.semibold)
              .foregroundColor(.green)
          }

          Text(
            "We've sent a confirmation email to \(email). Please check your inbox and click the confirmation link to activate your account."
          )
          .font(.system(.caption2, design: .rounded))
          .foregroundColor(.white.opacity(0.8))
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)

          VStack(spacing: 8) {
            // Resend Email Button
            Button(action: {
              Task {
                await supabaseManager.resendConfirmationEmail(email: email)
              }
            }) {
              HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                  .font(.caption2)
                Text("Resend Email")
                  .font(.system(.caption2, design: .rounded))
                  .fontWeight(.medium)
              }
              .foregroundColor(.blue)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .frame(maxWidth: .infinity)
              .background(resendButtonStyle)
              .overlay(
                RoundedRectangle(cornerRadius: 6)
                  .stroke(Color.blue.opacity(0.3), lineWidth: 1)
              )
            }
            .disabled(supabaseManager.isLoading)

            // Back to Sign In Button
            Button(action: {
              withAnimation(.easeInOut(duration: 0.3)) {
                showConfirmationMessage = false
                isSignUp = false
                email = ""
                password = ""
                confirmPassword = ""
                supabaseManager.errorMessage = nil
              }
            }) {
              HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                  .font(.caption2)
                Text("Back to Sign In")
                  .font(.system(.caption2, design: .rounded))
                  .fontWeight(.medium)
              }
              .foregroundColor(.white.opacity(0.7))
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .frame(maxWidth: .infinity)
              .background(backButtonStyle)
              .overlay(
                RoundedRectangle(cornerRadius: 6)
                  .stroke(Color.white.opacity(0.12), lineWidth: 1)
              )
            }
          }
        }
        .padding(12)
        .background(confirmationBackgroundStyle)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale))
      }

      // Error Message
      if let errorMessage = supabaseManager.errorMessage {
        HStack(spacing: 6) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundColor(.red)

          Text(errorMessage)
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

      // Auth Button
      if !showConfirmationMessage {
        Button(action: {
          Task {
            if isSignUp {
              await handleSignUp()
            } else {
              await handleSignIn()
            }
          }
        }) {
          HStack(spacing: 6) {
            if supabaseManager.isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.7)
            } else {
              Image(systemName: isSignUp ? "person.badge.plus" : "person.fill")
                .font(.caption)
            }

            Text(isSignUp ? "Sign Up" : "Sign In")
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
        .disabled(supabaseManager.isLoading || !isValidForm)
        .opacity((supabaseManager.isLoading || !isValidForm) ? 0.5 : 1)

        // Toggle Auth Mode
        Button(action: {
          withAnimation(.easeInOut(duration: 0.3)) {
            isSignUp.toggle()
            email = ""
            password = ""
            confirmPassword = ""
            supabaseManager.errorMessage = nil
          }
        }) {
          HStack(spacing: 4) {
            Image(systemName: isSignUp ? "person.fill" : "person.badge.plus")
              .font(.caption2)
            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
              .font(.system(.caption2, design: .rounded))
              .fontWeight(.medium)
          }
          .foregroundColor(.white.opacity(0.7))
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(
            Capsule()
              .fill(.ultraThinMaterial)
              .overlay(
                Capsule()
                  .stroke(Color.white.opacity(0.12), lineWidth: 1)
              )
          )
        }
      }
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

  private var isValidForm: Bool {
    let isEmailValid = email.contains("@") && email.contains(".")
    let isPasswordValid = password.count >= 6

    if isSignUp {
      return isEmailValid && isPasswordValid && password == confirmPassword
    } else {
      return isEmailValid && isPasswordValid
    }
  }

  private func handleSignUp() async {
    guard password == confirmPassword else {
      supabaseManager.errorMessage = "Passwords don't match"
      return
    }

    let success = await supabaseManager.signUp(email: email, password: password)
    if success {
      // Successfully signed up - show confirmation message
      print("User signed up successfully")
      withAnimation(.easeInOut(duration: 0.3)) {
        showConfirmationMessage = true
      }
    } else {
      // Authentication failed - error message is already set in SupabaseManager
      print("Sign up failed")
    }
  }

  private func handleSignIn() async {
    let success = await supabaseManager.signIn(email: email, password: password)
    if success {
      // Successfully signed in
      print("User signed in successfully")
      // Clear form on success
      email = ""
      password = ""
      confirmPassword = ""
    } else {
      // Authentication failed - error message is already set in SupabaseManager
      print("Sign in failed")
    }
  }
}

#Preview {
  AuthView()
}
