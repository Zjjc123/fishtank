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
    
    var body: some View {
        NavigationView {
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
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .animation(
                            Animation.linear(duration: Double.random(in: 3...8))
                                .repeatForever(autoreverses: false),
                            value: UUID()
                        )
                }
                
                VStack(spacing: 30) {
                    // App Logo/Title
                    VStack(spacing: 16) {
                        Image(systemName: "fish")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Fishtank")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Focus and collect fish")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 60)
                    
                    // Auth Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Confirm Password Field (only for sign up)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = supabaseManager.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Auth Button
                        Button(action: {
                            Task {
                                if isSignUp {
                                    await handleSignUp()
                                } else {
                                    await handleSignIn()
                                }
                            }
                        }) {
                            HStack {
                                if supabaseManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: isSignUp ? "person.badge.plus" : "person.fill")
                                        .font(.title3)
                                }
                                
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.8))
                            )
                        }
                        .disabled(supabaseManager.isLoading || !isValidForm)
                        
                        // Toggle Auth Mode
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                email = ""
                                password = ""
                                confirmPassword = ""
                                supabaseManager.errorMessage = nil
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
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
            // Successfully signed up
            print("User signed up successfully")
        }
    }
    
    private func handleSignIn() async {
        let success = await supabaseManager.signIn(email: email, password: password)
        if success {
            // Successfully signed in
            print("User signed in successfully")
        }
    }
}

#Preview {
    AuthView()
} 