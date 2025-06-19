//
//  FishCollectionView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct FishCollectionView: View {
  let collectedFish: [CollectedFish]
  let onFishSelected: (CollectedFish) -> Void
  let onVisibilityToggled: (CollectedFish) -> Bool
  @Binding var isPresented: Bool

  @State private var showLimitAlert = false

  private var visibleFish: [CollectedFish] {
    collectedFish.filter { $0.isVisible }
  }

  private var hiddenFish: [CollectedFish] {
    collectedFish.filter { !$0.isVisible }
  }

  private var rarityStats: [FishRarity: Int] {
    Dictionary(grouping: collectedFish, by: { $0.rarity })
      .mapValues { $0.count }
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      VStack {
        HStack {
          Text("Your Fish Collection")
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

        // Stats Section
        VStack(spacing: 8) {
          HStack {
            Text("Total Fish: \(collectedFish.count)")
              .font(.headline)
              .foregroundColor(.white)
            Spacer()
            Text(
              "Swimming: \(visibleFish.count)/\(AppConfig.maxSwimmingFish) | Hidden: \(hiddenFish.count)"
            )
            .font(.subheadline)
            .foregroundColor(visibleFish.count >= AppConfig.maxSwimmingFish ? .orange : .gray)
          }

          // Rarity breakdown
          HStack(spacing: 12) {
            ForEach(FishRarity.allCases, id: \.self) { rarity in
              let count = rarityStats[rarity] ?? 0
              VStack(spacing: 2) {
                Text("\(count)")
                  .font(.caption)
                  .fontWeight(.bold)
                  .foregroundColor(rarity.color)
                Text(rarity.rawValue.prefix(1))
                  .font(.system(size: 8))
                  .foregroundColor(rarity.color)
              }
            }
            Spacer()
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)

        ScrollView {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
            ForEach(collectedFish) { fish in
              VStack {
                Button(action: {
                  if fish.isVisible {
                    onFishSelected(fish)
                  }
                }) {
                  VStack {
                    Text(fish.emoji)
                      .font(.title)
                    Text(fish.rarity.rawValue)
                      .font(.caption)
                      .foregroundColor(fish.rarity.color)
                    Text(formatDate(fish.dateCaught))
                      .font(.system(size: 8))
                      .foregroundColor(.gray)
                  }
                  .padding(8)
                  .background(Color.blue.opacity(0.2))
                  .cornerRadius(8)
                  .opacity(fish.isVisible ? 1.0 : 0.6)
                }
                .disabled(!fish.isVisible)

                // Visibility Toggle Button
                Button(action: {
                  let success = onVisibilityToggled(fish)
                  if !success {
                    showLimitAlert = true
                  }
                }) {
                  Image(systemName: fish.isVisible ? "eye.fill" : "eye.slash.fill")
                    .font(.caption)
                    .foregroundColor(fish.isVisible ? .green : .red)
                    .padding(4)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
                }
              }
            }
          }
          .padding()
        }

        Text("👁️ = Swimming in tank | 👁️‍🗨️ = Hidden from tank")
          .font(.system(size: 10))
          .foregroundColor(.gray)
        Text("Maximum \(AppConfig.maxSwimmingFish) fish can swim at once")
          .font(.system(size: 10))
          .foregroundColor(.orange)
          .padding(.bottom)
      }
      .background(Color.black.opacity(0.9))
      .cornerRadius(15)
      .padding(.horizontal, 20)
      .padding(.vertical, 40)
    }
    .alert("Tank Full!", isPresented: $showLimitAlert) {
      Button("OK") {}
    } message: {
      Text(
        "You can only have \(AppConfig.maxSwimmingFish) fish swimming at once. Hide some fish first to make room for new ones."
      )
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
}
