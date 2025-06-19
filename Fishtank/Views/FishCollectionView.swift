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
  let onVisibilityToggled: (CollectedFish) -> Void
  @Binding var isPresented: Bool
  @State private var showHiddenFish = false

  private var visibleFish: [CollectedFish] {
    collectedFish.filter { $0.isVisible }
  }

  private var hiddenFish: [CollectedFish] {
    collectedFish.filter { !$0.isVisible }
  }

  private var displayedFish: [CollectedFish] {
    showHiddenFish ? hiddenFish : visibleFish
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

        // Filter Toggle
        HStack {
          Button(action: {
            showHiddenFish = false
          }) {
            Text("Visible (\(visibleFish.count))")
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(showHiddenFish ? Color.gray.opacity(0.3) : Color.blue.opacity(0.6))
              .foregroundColor(.white)
              .cornerRadius(15)
          }

          Button(action: {
            showHiddenFish = true
          }) {
            Text("Hidden (\(hiddenFish.count))")
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(showHiddenFish ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3))
              .foregroundColor(.white)
              .cornerRadius(15)
          }

          Spacer()
        }
        .padding(.horizontal)

        ScrollView {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
            ForEach(displayedFish) { fish in
              VStack {
                Button(action: {
                  if !showHiddenFish {
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
                  .opacity(showHiddenFish ? 0.6 : 1.0)
                }
                .disabled(showHiddenFish)

                // Visibility Toggle Button
                Button(action: {
                  onVisibilityToggled(fish)
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

        Text(
          showHiddenFish
            ? "Hidden fish are not displayed in the tank"
            : "All visible fish are automatically displayed in the tank"
        )
        .font(.caption)
        .foregroundColor(.gray)
        .padding(.bottom)

        Text("👁️ = Swimming in tank | 👁️‍🗨️ = Hidden from tank")
          .font(.system(size: 10))
          .foregroundColor(.gray)
          .padding(.bottom)
      }
      .background(Color.black.opacity(0.9))
      .cornerRadius(15)
      .padding(.horizontal, 20)
      .padding(.vertical, 40)
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
}
