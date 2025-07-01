//
//  SettingsView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct SettingsView: View {
  @Binding var isPresented: Bool
  let statsManager: GameStatsManager
  let fishTankManager: FishTankManager
  @State private var showingClearAlert = false

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
              Text("Fish are automatically saved to your device")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.blue.opacity(0.8))
                .multilineTextAlignment(.leading)
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

        // Buttons
        VStack(spacing: 8) {
          Button(action: {
            showingClearAlert = true
          }) {
            HStack(spacing: 8) {
              Image(systemName: "trash.fill")
                .font(.subheadline)
              Text("Clear All Fish")
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
    }
    .alert("Clear All Fish", isPresented: $showingClearAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Clear All", role: .destructive) {
        statsManager.clearAllFish(fishTankManager: fishTankManager)
      }
    } message: {
      Text("This will permanently delete all your collected fish. This action cannot be undone.")
    }
  }
}
