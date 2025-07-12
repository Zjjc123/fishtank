//
//  AuthView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Combine
import SwiftUI
import UIKit

// MARK: - Keyboard Dismissal Extension
extension View {
  func dismissKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

// MARK: - Keyboard Adaptive Modifier
struct KeyboardAdaptive: ViewModifier {
  @State private var keyboardHeight: CGFloat = 0

  func body(content: Content) -> some View {
    GeometryReader { geometry in
      content
        .padding(.bottom, max(0, keyboardHeight - geometry.safeAreaInsets.bottom))
        .animation(.easeOut(duration: 0.16), value: keyboardHeight)
        .onReceive(Publishers.keyboardHeight) { height in
          self.keyboardHeight = height
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
  }
}

extension View {
  func keyboardAdaptive() -> some View {
    self.modifier(KeyboardAdaptive())
  }
}

// MARK: - Keyboard Publisher
extension Publishers {
  static var keyboardHeight: AnyPublisher<CGFloat, Never> {
    let willShow = NotificationCenter.default.publisher(
      for: UIResponder.keyboardWillShowNotification
    )
    .map { notification -> CGFloat in
      (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }

    let willHide = NotificationCenter.default.publisher(
      for: UIResponder.keyboardWillHideNotification
    )
    .map { _ -> CGFloat in 0 }

    return MergeMany(willShow, willHide)
      .eraseToAnyPublisher()
  }
}

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
          .onTapGesture {
            dismissKeyboard()
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
      UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
      AppDelegate.orientationLock = .portrait
      UIViewController.attemptRotationToDeviceOrientation()
    }
    .onDisappear {
      UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
      AppDelegate.orientationLock = .landscape
      UIViewController.attemptRotationToDeviceOrientation()
    }
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

  // Add state for OTP verification
  @State private var otpCode: String = ""
  @State private var isVerifyingOTP: Bool = false

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

  // Extract common styles to reduce complexity
  private func textFieldBackground() -> some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color.white.opacity(0.15))
  }

  private func textFieldBorder() -> some View {
    RoundedRectangle(cornerRadius: 8)
      .stroke(Color.white.opacity(0.2), lineWidth: 1)
  }

  private func buttonDisabledState() -> Bool {
    otpCode.count != 6 || isVerifyingOTP || supabaseManager.isLoading
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
              .background(textFieldBackground())
              .overlay(textFieldBorder())
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
            .background(textFieldBackground())
            .overlay(textFieldBorder())
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
                .background(textFieldBackground())
                .overlay(textFieldBorder())
                .foregroundColor(.white)
            }
          }
        }
      }

      // Confirmation Message with OTP Input
      if showConfirmationMessage {
        confirmationView()
      }

      // Error Message
      if let errorMessage = supabaseManager.errorMessage {
        errorView(message: errorMessage)
      }

      // Auth Button
      if !showConfirmationMessage {
        authButtonsView()
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

  // MARK: - Extracted Views

  @ViewBuilder
  private func confirmationView() -> some View {
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
        "We've sent a verification code to \(email). Please enter the 6-digit code below to verify your account."
      )
      .font(.system(.caption2, design: .rounded))
      .foregroundColor(.white.opacity(0.8))
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)

      // OTP Input Field
      VStack(alignment: .leading, spacing: 4) {
        Text("Verification Code")
          .font(.system(.caption2, design: .rounded))
          .foregroundColor(.white.opacity(0.7))

        TextField("Enter 6-digit code", text: $otpCode)
          .font(.system(.callout, design: .rounded))
          .padding(8)
          .frame(height: 36)
          .background(textFieldBackground())
          .overlay(textFieldBorder())
          .foregroundColor(.white)
          .keyboardType(.numberPad)
          .onChange(of: otpCode) { newValue in
            // Limit to 6 digits
            if newValue.count > 6 {
              otpCode = String(newValue.prefix(6))
            }
            // Ensure only digits
            otpCode = newValue.filter { $0.isNumber }
          }
      }

      // Verify Button
      verifyButton()

      VStack(spacing: 8) {
        // Resend Email Button
        resendButton()

        // Back to Sign In Button
        backToSignInButton()
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

  @ViewBuilder
  private func verifyButton() -> some View {
    Button(action: {
      Task {
        await verifyOTP()
      }
    }) {
      HStack(spacing: 6) {
        if isVerifyingOTP {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            .scaleEffect(0.7)
        } else {
          Image(systemName: "checkmark.circle.fill")
            .font(.caption2)
        }

        Text("Verify Account")
          .font(.system(.caption2, design: .rounded))
          .fontWeight(.medium)
      }
      .foregroundColor(.blue)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.blue.opacity(0.1))
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color.blue.opacity(0.3), lineWidth: 1)
          )
      )
    }
    .disabled(buttonDisabledState())
    .opacity(buttonDisabledState() ? 0.5 : 1)
  }

  @ViewBuilder
  private func resendButton() -> some View {
    Button(action: {
      Task {
        await supabaseManager.resendConfirmationEmail(email: email)
      }
    }) {
      HStack(spacing: 4) {
        Image(systemName: "arrow.clockwise")
          .font(.caption2)
        Text("Resend Code")
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
    .disabled(supabaseManager.isLoading || isVerifyingOTP)
    .opacity((supabaseManager.isLoading || isVerifyingOTP) ? 0.5 : 1)
  }

  @ViewBuilder
  private func backToSignInButton() -> some View {
    Button(action: {
      withAnimation(.easeInOut(duration: 0.3)) {
        showConfirmationMessage = false
        isSignUp = false
        email = ""
        password = ""
        confirmPassword = ""
        otpCode = ""
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
    .disabled(isVerifyingOTP)
    .opacity(isVerifyingOTP ? 0.5 : 1)
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
  private func authButtonsView() -> some View {
    VStack(spacing: 16) {
      // Sign In/Up Button
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

  private func verifyOTP() async {
    isVerifyingOTP = true
    let success = await supabaseManager.verifyEmailWithOTP(email: email, token: otpCode)
    isVerifyingOTP = false

    if success {
      // Successfully verified and signed in
      print("User verified and signed in successfully")
      // Clear form on success
      email = ""
      password = ""
      confirmPassword = ""
      otpCode = ""
      showConfirmationMessage = false
    } else {
      // Verification failed - error message is already set in SupabaseManager
      print("OTP verification failed")
    }
  }
}

#Preview {
  AuthView()
}
