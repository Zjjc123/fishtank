//
//  PasswordResetView.swift
//  Fishtank
//
//  Created by Claude on 7/1/25.
//

import Supabase
import SwiftUI

struct PasswordResetView: View {
  @StateObject private var supabaseManager = SupabaseManager.shared
  @State private var email: String
  @State private var otpCode = ""
  @State private var newPassword = ""
  @State private var confirmPassword = ""
  @State private var showPassword = false
  @State private var currentStep: ResetStep = .requestOTP
  @State private var isVerifyingOTP = false
  @State private var isResettingPassword = false
  @Environment(\.dismiss) private var dismiss

  // Initialize with an email if provided from the auth screen
  init(initialEmail: String = "") {
    _email = State(initialValue: initialEmail)
  }

  enum ResetStep {
    case requestOTP
    case verifyOTP
    case resetPassword
  }

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

            Text("Reset Password")
              .font(.system(.largeTitle, design: .rounded))
              .fontWeight(.bold)
              .foregroundColor(.white)

            Text(stepDescription)
              .font(.system(.subheadline, design: .rounded))
              .foregroundColor(.white.opacity(0.8))
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .padding(.top, 60)
          .onTapGesture {
            dismissKeyboard()
          }

          // Form content based on current step
          VStack(spacing: 16) {
            switch currentStep {
            case .requestOTP:
              requestOTPView()
            case .verifyOTP:
              verifyOTPView()
            case .resetPassword:
              resetPasswordView()
            }

            // Error Message
            if let errorMessage = supabaseManager.errorMessage {
              errorView(message: errorMessage)
            }

            // Success Message
            if let successMessage = supabaseManager.successMessage {
              successView(message: successMessage)
            }

            // Back to Sign In Button
            backToSignInButton()
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
          .padding(.horizontal, 30)

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
    }
    .onDisappear {
      // Clear success messages when the view disappears
      supabaseManager.successMessage = nil
    }
  }

  // MARK: - Step-specific Views

  private var stepDescription: String {
    switch currentStep {
    case .requestOTP:
      return "Enter your email to receive a verification code"
    case .verifyOTP:
      return "Enter the verification code sent to your email"
    case .resetPassword:
      return "Create a new password for your account"
    }
  }

  @ViewBuilder
  private func requestOTPView() -> some View {
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

    // Request OTP Button
    Button(action: {
      Task {
        await requestOTP()
      }
    }) {
      HStack(spacing: 6) {
        if supabaseManager.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.7)
        } else {
          Image(systemName: "envelope.fill")
            .font(.caption)
        }

        Text("Send Verification Code")
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
    .disabled(supabaseManager.isLoading || !isValidEmail)
    .opacity((supabaseManager.isLoading || !isValidEmail) ? 0.5 : 1)
  }

  @ViewBuilder
  private func verifyOTPView() -> some View {
    // Email display
    HStack(spacing: 6) {
      Image(systemName: "envelope.fill")
        .font(.caption2)
        .foregroundColor(.green)

      Text("Code sent to \(email)")
        .font(.system(.caption2, design: .rounded))
        .foregroundColor(.white.opacity(0.8))
    }
    .padding(.vertical, 4)

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

    // Verify OTP Button
    Button(action: {
      Task {
        await verifyOTP()
      }
    }) {
      HStack(spacing: 6) {
        if isVerifyingOTP {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.7)
        } else {
          Image(systemName: "checkmark.circle.fill")
            .font(.caption)
        }

        Text("Verify Code")
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
    .disabled(isVerifyingOTP || otpCode.count != 6)
    .opacity((isVerifyingOTP || otpCode.count != 6) ? 0.5 : 1)

    // Resend Button
    Button(action: {
      Task {
        await requestOTP()
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
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.blue.opacity(0.1))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.blue.opacity(0.3), lineWidth: 1)
      )
    }
    .disabled(supabaseManager.isLoading || isVerifyingOTP)
    .opacity((supabaseManager.isLoading || isVerifyingOTP) ? 0.5 : 1)
  }

  @ViewBuilder
  private func resetPasswordView() -> some View {
    // New Password Field
    VStack(alignment: .leading, spacing: 4) {
      Text("New Password")
        .font(.system(.caption2, design: .rounded))
        .foregroundColor(.white.opacity(0.7))

      HStack(spacing: 6) {
        if showPassword {
          TextField("Enter new password", text: $newPassword)
            .font(.system(.callout, design: .rounded))
        } else {
          SecureField("Enter new password", text: $newPassword)
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

    // Confirm Password Field
    VStack(alignment: .leading, spacing: 4) {
      Text("Confirm Password")
        .font(.system(.caption2, design: .rounded))
        .foregroundColor(.white.opacity(0.7))

      SecureField("Confirm new password", text: $confirmPassword)
        .font(.system(.callout, design: .rounded))
        .padding(8)
        .frame(height: 36)
        .background(textFieldBackground())
        .overlay(textFieldBorder())
        .foregroundColor(.white)
    }

    // Reset Password Button
    Button(action: {
      Task {
        await resetPassword()
      }
    }) {
      HStack(spacing: 6) {
        if isResettingPassword {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.7)
        } else {
          Image(systemName: "lock.fill")
            .font(.caption)
        }

        Text("Reset Password")
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
    .disabled(isResettingPassword || !isValidNewPassword)
    .opacity((isResettingPassword || !isValidNewPassword) ? 0.5 : 1)
  }

  // MARK: - Helper Views

  @ViewBuilder
  private func backToSignInButton() -> some View {
    Button(action: {
      dismiss()
    }) {
      HStack(spacing: 4) {
        Image(systemName: "arrow.left")
          .font(.caption2)
        Text("Back to Sign In")
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
  }

  // MARK: - Helper Functions

  private func textFieldBackground() -> some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color.white.opacity(0.15))
  }

  private func textFieldBorder() -> some View {
    RoundedRectangle(cornerRadius: 8)
      .stroke(Color.white.opacity(0.2), lineWidth: 1)
  }

  private var isValidEmail: Bool {
    email.contains("@") && email.contains(".")
  }

  private var isValidNewPassword: Bool {
    newPassword.count >= 6 && newPassword == confirmPassword
  }

  private func dismissKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

  // MARK: - Password Reset Logic

  private func requestOTP() async {
    guard isValidEmail else {
      supabaseManager.errorMessage = "Please enter a valid email address"
      return
    }

    // Send password reset OTP
    let success = await supabaseManager.resetPasswordForEmail(email: email)

    if success {
      currentStep = .verifyOTP
      supabaseManager.successMessage = "Verification code sent to your email"
    }
    // Error message is set by SupabaseManager if there was an error
  }

  private func verifyOTP() async {
    guard otpCode.count == 6 else {
      supabaseManager.errorMessage = "Please enter the 6-digit verification code"
      return
    }

    isVerifyingOTP = true

    // Verify the OTP code
    let success = await supabaseManager.verifyOTP(email: email, token: otpCode, type: .recovery)

    isVerifyingOTP = false

    if success {
      currentStep = .resetPassword
      supabaseManager.successMessage = "Verification successful. Please set a new password."
    }
    // Error message is set by SupabaseManager if there was an error
  }

  private func resetPassword() async {
    guard isValidNewPassword else {
      supabaseManager.errorMessage = "Passwords must match and be at least 6 characters"
      return
    }

    isResettingPassword = true

    // Update the password
    let success = await supabaseManager.updatePassword(newPassword: newPassword)

    isResettingPassword = false

    if success {
      supabaseManager.successMessage = "Password has been reset successfully"
      // Delay to allow the user to read the success message
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        dismiss()
      }
    }
    // Error message is set by SupabaseManager if there was an error
  }
}

#Preview {
  PasswordResetView()
}
