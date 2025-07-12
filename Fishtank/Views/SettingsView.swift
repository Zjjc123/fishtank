//
//  SettingsView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Supabase
import SwiftUI

struct SettingsView: View {
  @Binding var isPresented: Bool
  let statsManager: GameStateManager
  let fishTankManager: FishTankManager
  @StateObject private var supabaseManager = SupabaseManager.shared
  @State private var showingSignOutAlert = false
  @State private var isOnline = true
  
  private func signOut() async {
    await supabaseManager.signOut()
  }
  
  private func checkConnection() {
    Task {
      // Simple network check by trying to make a connection
      do {
        let url = URL(string: "https://www.apple.com")!
        let (_, response) = try await URLSession.shared.data(from: url)
        
        await MainActor.run {
          isOnline = (response as? HTTPURLResponse)?.statusCode == 200
        }
      } catch {
        await MainActor.run {
          isOnline = false
        }
      }
    }
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      VStack(spacing: 16) {
        // Header
        HStack(spacing: 8) {
          Image(systemName: "gearshape.fill")
            .font(.title3)
            .foregroundColor(.white.opacity(0.9))

          Text("Settings")
            .font(.system(.headline, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(.white)
        }
        .padding(.top, 6)

        // Connection Status
        HStack(spacing: 8) {
          Image(systemName: isOnline ? "wifi" : "wifi.slash")
            .font(.title3)
            .foregroundColor(isOnline ? .green.opacity(0.9) : .red.opacity(0.9))

          Text("Connection Status")
            .font(.system(.subheadline, design: .rounded))
            .foregroundColor(.white.opacity(0.8))

          Spacer()

          Text(isOnline ? "Online" : "Offline")
            .font(.system(.headline, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(isOnline ? .green : .red)
        }
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )

        // Settings Options
        VStack(spacing: 12) {
          // Storage Info
          VStack(spacing: 8) {
            HStack(spacing: 8) {
              Image(systemName: "externaldrive.fill")
                .font(.title3)
                .foregroundColor(.blue.opacity(0.9))

              Text("Storage Information")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

              Spacer()

              Text("\(statsManager.fishCount)")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }

            HStack(spacing: 6) {
              Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.8))
              if supabaseManager.isAuthenticated && isOnline {
                Text("Fish are synced to your account")
                  .font(.system(.caption, design: .rounded))
                  .foregroundColor(.blue.opacity(0.8))
                  .multilineTextAlignment(.leading)
              } else if supabaseManager.isAuthenticated && !isOnline {
                Text("Fish are saved locally (offline mode, will sync when online)")
                  .font(.system(.caption, design: .rounded))
                  .foregroundColor(.orange.opacity(0.8))
                  .multilineTextAlignment(.leading)
              } else {
                Text("Fish are saved locally on your device")
                  .font(.system(.caption, design: .rounded))
                  .foregroundColor(.blue.opacity(0.8))
                  .multilineTextAlignment(.leading)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(.ultraThinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.white.opacity(0.2), lineWidth: 1)
              )
          )
        }

        // Sync Button (if authenticated but offline)
        if supabaseManager.isAuthenticated && !isOnline {
          Button(action: {
            checkConnection()
            if isOnline {
              Task {
                await statsManager.triggerSupabaseSync()
              }
            }
          }) {
            HStack(spacing: 8) {
              Image(systemName: "arrow.triangle.2.circlepath")
                .font(.subheadline)
              Text("Try to Sync")
                .font(.system(.subheadline, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.7))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            )
          }
        }

        // Buttons
        VStack(spacing: 8) {
          // Account Section (if authenticated)
          if supabaseManager.isAuthenticated {
            VStack(spacing: 8) {
              HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                  .font(.title3)
                  .foregroundColor(.green.opacity(0.9))

                Text("Account")
                  .font(.system(.subheadline, design: .rounded))
                  .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text(supabaseManager.currentUser?.email ?? "")
                  .font(.system(.caption, design: .rounded))
                  .foregroundColor(.green.opacity(0.8))
              }
              .padding(12)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(.ultraThinMaterial)
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
            }
          }

          // Sign Out Button (if authenticated)
          if supabaseManager.isAuthenticated {
            Button(action: {
              showingSignOutAlert = true
            }) {
              HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                  .font(.subheadline)
                Text("Sign Out")
                  .font(.system(.subheadline, design: .rounded))
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 40)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.red.opacity(0.7))
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.red.opacity(0.3), lineWidth: 1)
                  )
              )
            }
          }

          Button(action: {
            isPresented = false
          }) {
            HStack(spacing: 6) {
              Image(systemName: "xmark.circle")
                .font(.subheadline)
              Text("Close")
                .font(.system(.subheadline, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            )
          }
        }
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
          )
      )
      .padding(.horizontal, 100)
      .onAppear {
        checkConnection()
      }
    }

    .alert("Sign Out", isPresented: $showingSignOutAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Sign Out", role: .destructive) {
        Task {
          await signOut()
        }
      }
    } message: {
      Text(
        "Are you sure you want to sign out? Your fish collection will remain saved to your account."
      )
    }
  }
}
