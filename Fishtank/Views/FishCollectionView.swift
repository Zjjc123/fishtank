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
  @State private var selectedTab = 0

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

  // Create a dictionary of discovered fish names by rarity
  private var discoveredFishByRarity: [FishRarity: Set<String>] {
    var discovered: [FishRarity: Set<String>] = [:]
    for fish in collectedFish {
      if discovered[fish.rarity] == nil {
        discovered[fish.rarity] = []
      }
      discovered[fish.rarity]?.insert(fish.name)
    }
    return discovered
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
          if selectedTab == 0 {
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
        }
        .padding(.top, 4)

        // Tab Selector
        Picker("View", selection: $selectedTab) {
          Text("Collection").tag(0)
          Text("FishDex").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)

        GeometryReader { geometry in
          if selectedTab == 0 {
            // Collection View
            CollectionTabView(
              collectedFish: collectedFish,
              visibleFish: visibleFish,
              sortedFish: sortedFish,
              onFishSelected: onFishSelected,
              onVisibilityToggled: onVisibilityToggled,
              showLimitAlert: $showLimitAlert,
              geometry: geometry
            )
          } else {
            // FishDex View
            FishDexTabView(
              discoveredFishByRarity: discoveredFishByRarity,
              onFishSelected: onFishSelected,
              geometry: geometry
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

// MARK: - Collection Tab View
struct CollectionTabView: View {
  let collectedFish: [CollectedFish]
  let visibleFish: [CollectedFish]
  let sortedFish: [CollectedFish]
  let onFishSelected: (CollectedFish) -> Void
  let onVisibilityToggled: (CollectedFish) -> Bool
  @Binding var showLimitAlert: Bool
  let geometry: GeometryProxy

  var body: some View {
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

  private func columnCount(for width: CGFloat) -> Int {
    let availableWidth = width - 16
    let columnWidth: CGFloat = 80
    let calculatedColumns = Int(availableWidth / columnWidth)
    return max(4, min(10, calculatedColumns))
  }
}

// MARK: - FishDex Tab View
struct FishDexTabView: View {
  let discoveredFishByRarity: [FishRarity: Set<String>]
  let onFishSelected: (CollectedFish) -> Void
  let geometry: GeometryProxy

  var body: some View {
    VStack(spacing: 8) {
      // Stats Panel
      HStack(spacing: 8) {
        ForEach(FishRarity.allCases, id: \.self) { rarity in
          let totalInRarity = rarity.fishOptions.count
          let discoveredCount = discoveredFishByRarity[rarity]?.count ?? 0

          HStack(spacing: 4) {
            Circle()
              .fill(rarity.color)
              .frame(width: 8, height: 8)

            Text("\(discoveredCount)/\(totalInRarity)")
              .font(.system(.caption2, design: .rounded))
              .foregroundColor(.white)
          }
          .padding(.horizontal, 6)
          .padding(.vertical, 4)
          .background(
            RoundedRectangle(cornerRadius: 6)
              .fill(.ultraThinMaterial)
          )
        }
      }

      // Fish Grid by Rarity
      ScrollView {
        VStack(spacing: 16) {
          ForEach(FishRarity.allCases, id: \.self) { rarity in
            VStack(alignment: .leading, spacing: 8) {
              // Rarity Header
              HStack {
                Circle()
                  .fill(rarity.color)
                  .frame(width: 12, height: 12)
                Text(rarity.rawValue)
                  .font(.system(.subheadline, design: .rounded))
                  .fontWeight(.semibold)
                  .foregroundColor(rarity.color)
              }
              .padding(.horizontal)

              // Fish Grid for this Rarity
              LazyVGrid(
                columns: Array(
                  repeating: GridItem(.flexible(), spacing: 8),
                  count: columnCount(for: geometry.size.width)
                ),
                spacing: 8
              ) {
                ForEach(rarity.fishOptions, id: \.name) { fish in
                  let isDiscovered = discoveredFishByRarity[rarity]?.contains(fish.name) ?? false
                  FishDexItemView(
                    name: fish.name,
                    imageName: fish.imageName,
                    rarity: rarity,
                    isDiscovered: isDiscovered
                  )
                }
              }
              .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            )
          }
        }
        .padding(8)
      }
    }
  }

  private func columnCount(for width: CGFloat) -> Int {
    let availableWidth = width - 32
    let columnWidth: CGFloat = 80
    let calculatedColumns = Int(availableWidth / columnWidth)
    return max(4, min(10, calculatedColumns))
  }
}

// MARK: - FishDex Item View
struct FishDexItemView: View {
  let name: String
  let imageName: String
  let rarity: FishRarity
  let isDiscovered: Bool

  var body: some View {
    VStack(spacing: 2) {
      if isDiscovered {
        Image(imageName)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: 32, height: 32)
      } else {
        Image(systemName: "questionmark.circle.fill")
          .font(.system(size: 32))
          .foregroundColor(.gray.opacity(0.5))
      }

      Text(isDiscovered ? name : "???")
        .font(.system(.caption2, design: .rounded))
        .fontWeight(.medium)
        .foregroundColor(isDiscovered ? .white : .gray)
        .lineLimit(1)

      Text(rarity.rawValue)
        .font(.system(.caption2, design: .rounded))
        .foregroundColor(isDiscovered ? rarity.color.opacity(0.9) : .gray.opacity(0.5))
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
    .opacity(isDiscovered ? 1 : 0.6)
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
