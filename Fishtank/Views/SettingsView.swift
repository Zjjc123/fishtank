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
  @State private var showingClearAlert = false
  @State private var showingExportSheet = false
  @State private var exportData = ""

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      VStack(spacing: 20) {
        HStack {
          Text("Settings")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
          Spacer()
          Button("Done") {
            isPresented = false
          }
          .foregroundColor(.blue)
        }
        .padding()

        VStack(spacing: 15) {
          // Export Collection
          Button(action: {
            exportData = statsManager.exportFishCollection()
            showingExportSheet = true
          }) {
            HStack {
              Image(systemName: "square.and.arrow.up")
              Text("Export Fish Collection")
              Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(10)
            .foregroundColor(.white)
          }

          // Clear All Fish
          Button(action: {
            showingClearAlert = true
          }) {
            HStack {
              Image(systemName: "trash")
              Text("Clear All Fish")
              Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.2))
            .cornerRadius(10)
            .foregroundColor(.red)
          }

          // Storage Info
          VStack(alignment: .leading, spacing: 5) {
            Text("Storage Information")
              .font(.headline)
              .foregroundColor(.white)
            Text("Fish are automatically saved to your device")
              .font(.caption)
              .foregroundColor(.gray)
            Text("Total fish: \(statsManager.fishCount)")
              .font(.caption)
              .foregroundColor(.gray)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .background(Color.gray.opacity(0.2))
          .cornerRadius(10)
        }
        .padding(.horizontal)

        Spacer()
      }
      .background(Color.black.opacity(0.9))
      .cornerRadius(15)
      .padding(.horizontal, 30)
      .padding(.vertical, 50)
    }
    .alert("Clear All Fish", isPresented: $showingClearAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Clear All", role: .destructive) {
        statsManager.clearAllFish()
      }
    } message: {
      Text("This will permanently delete all your collected fish. This action cannot be undone.")
    }
    .sheet(isPresented: $showingExportSheet) {
      ExportView(exportData: exportData)
    }
  }
}
