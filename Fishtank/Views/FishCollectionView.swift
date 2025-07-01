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
  @AppStorage("FishCollectionSortOption") private var sortOption: SortOption = .time
  @AppStorage("FishCollectionSortDirection") private var sortDirection: SortDirection = .descending

  enum SortOption: String, CaseIterable {
    case time = "Time"
    case rarity = "Rarity"

    var displayName: String {
      switch self {
      case .time: return "Time"
      case .rarity: return "Rarity"
      }
    }
  }

  enum SortDirection: String {
    case ascending, descending

    var icon: String {
      switch self {
      case .ascending: return "chevron.up"
      case .descending: return "chevron.down"
      }
    }
  }

  private var sortedFish: [CollectedFish] {
    let sorted =
      switch sortOption {
      case .time:
        collectedFish.sorted { $0.dateCaught > $1.dateCaught }
      case .rarity:
        collectedFish.sorted { $0.rarity.sortOrder > $1.rarity.sortOrder }
      }

    if sortDirection == .ascending {
      return sorted.reversed()
    } else {
      return sorted
    }
  }

  private var visibleFish: [CollectedFish] {
    sortedFish.filter { $0.isVisible }
  }

  private var hiddenFish: [CollectedFish] {
    sortedFish.filter { !$0.isVisible }
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      VStack(spacing: 8) {
        // Header
        HStack(spacing: 8) {
          Image(systemName: "fish.fill")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.9))

          Text("Fish Collection")
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(.white)

          Spacer()

          // Sort Controls
          HStack(spacing: 6) {
            Button(action: {
              sortOption = sortOption == .time ? .rarity : .time
            }) {
              HStack(spacing: 4) {
                Text(sortOption.displayName)
                  .font(.system(.caption2, design: .rounded))
                  .fontWeight(.medium)
                Image(systemName: "chevron.left.chevron.right")
                  .font(.caption2)
              }
              .foregroundColor(.white)
              .padding(.horizontal, 6)
              .frame(height: 24)
              .background(
                RoundedRectangle(cornerRadius: 6)
                  .fill(.ultraThinMaterial)
              )
            }

            Button(action: {
              sortDirection = sortDirection == .ascending ? .descending : .ascending
            }) {
              Image(systemName: sortDirection.icon)
                .font(.caption2)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                  RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
                )
            }
          }
        }
        .padding(.top, 4)

        GeometryReader { geometry in
          VStack(spacing: 8) {
            // Stats Panel as horizontal row
            HStack(spacing: 8) {
              // Total Fish Stats
              HStack(spacing: 6) {
                Image(systemName: "number.circle.fill")
                  .font(.subheadline)
                  .foregroundColor(.blue.opacity(0.9))

                VStack(alignment: .leading, spacing: 0) {
                  Text("Total Fish")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                  Text("\(collectedFish.count)")
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
              }
              .padding(6)
              .frame(maxWidth: .infinity)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(.ultraThinMaterial)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )

              // Swimming Stats
              HStack(spacing: 6) {
                Image(systemName: "figure.water.fitness")
                  .font(.subheadline)
                  .foregroundColor(
                    visibleFish.count >= AppConfig.maxSwimmingFish
                      ? .orange.opacity(0.9) : .green.opacity(0.9))

                VStack(alignment: .leading, spacing: 0) {
                  Text("Swimming")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                  HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(visibleFish.count)/\(AppConfig.maxSwimmingFish)")
                      .font(.system(.callout, design: .rounded))
                      .fontWeight(.bold)
                      .foregroundColor(
                        visibleFish.count >= AppConfig.maxSwimmingFish ? .orange : .green)

                    if visibleFish.count >= AppConfig.maxSwimmingFish {
                      Text("max")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.orange.opacity(0.8))
                    }
                  }
                }
              }
              .padding(6)
              .frame(maxWidth: .infinity)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(.ultraThinMaterial)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
            }

            // Fish Grid
            ScrollView {
              LazyVGrid(
                columns: Array(
                  repeating: GridItem(.flexible(), spacing: 8),
                  count: columnCount(for: geometry.size.width)
                ),
                spacing: 8
              ) {
                ForEach(sortedFish) { fish in
                  FishItemView(
                    fish: fish,
                    onFishSelected: onFishSelected,
                    onVisibilityToggled: onVisibilityToggled,
                    showLimitAlert: $showLimitAlert
                  )
                }
              }
              .padding(8)
            }
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            )
          }
        }

        // Footer
        Button(action: {
          isPresented = false
        }) {
          HStack(spacing: 4) {
            Image(systemName: "xmark.circle")
              .font(.caption)
            Text("Close")
              .font(.system(.caption, design: .rounded))
          }
          .foregroundColor(.white.opacity(0.7))
          .frame(maxWidth: .infinity)
          .frame(height: 28)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(.ultraThinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.white.opacity(0.2), lineWidth: 1)
              )
          )
        }
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
          )
      )
      .padding(.horizontal, 80)
      .padding(.bottom, 30)
      .padding(.top, 30)
    }
  }

  private func columnCount(for width: CGFloat) -> Int {
    let availableWidth = width - 16  // Reduced from 24
    let columnWidth: CGFloat = 80  // Reduced from 100
    let calculatedColumns = Int(availableWidth / columnWidth)
    return max(4, min(10, calculatedColumns))  // Increased min and max columns due to smaller size
  }
}

struct FishItemView: View {
  let fish: CollectedFish
  let onFishSelected: (CollectedFish) -> Void
  let onVisibilityToggled: (CollectedFish) -> Bool
  @Binding var showLimitAlert: Bool

  var body: some View {
    VStack(spacing: 2) {
      Button(action: {
        onFishSelected(fish)
      }) {
        VStack(spacing: 2) {
          Image(fish.imageName)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32)

          Text(fish.name)
            .font(.system(.caption2, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(.white)
            .lineLimit(1)

          Text(fish.rarity.rawValue)
            .font(.system(.caption2, design: .rounded))
            .foregroundColor(fish.rarity.color.opacity(0.9))

          Text(formatDate(fish.dateCaught))
            .font(.system(.caption2, design: .rounded))
            .foregroundColor(.gray.opacity(0.7))
        }
        .frame(width: 70)
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(.ultraThinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        )
        .opacity(fish.isVisible ? 1 : 0.6)
      }

      Button(action: {
        let success = onVisibilityToggled(fish)
        if !success {
          showLimitAlert = true
        }
      }) {
        HStack(spacing: 2) {
          Image(systemName: fish.isVisible ? "eye.fill" : "eye.slash.fill")
            .font(.caption2)
          Text(fish.isVisible ? "Hide" : "Show")
            .font(.system(.caption2, design: .rounded))
        }
        .foregroundColor(fish.isVisible ? .green : .red)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(.ultraThinMaterial)
        )
      }
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
}
