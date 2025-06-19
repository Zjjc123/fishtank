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

  var body: some View {
    ZStack {
      backgroundOverlay
      mainContent
    }
  }

  private var backgroundOverlay: some View {
    Color.black.opacity(0.3)
      .ignoresSafeArea()
      .onTapGesture {
        isPresented = false
      }
  }

  private var mainContent: some View {
    VStack {
      headerSection

      GeometryReader { geometry in
        HStack(spacing: 16) {
          statsPanel
          fishGridSection(geometry: geometry)
        }
      }

      footerSection
    }
    .background(contentBackground)
    .padding(.horizontal, 20)
    .padding(.vertical, 40)
  }

  private var headerSection: some View {
    HStack {
      Text("Your Fish Collection")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .opacity(0.9)
      Spacer()
      Button("Done") {
        isPresented = false
      }
      .foregroundColor(.blue)
      .opacity(0.8)
    }
    .padding()
  }

  private var statsPanel: some View {
    VStack(alignment: .leading, spacing: 12) {
      statsSection
      Spacer(minLength: 0)
    }
    .frame(width: 100)
    .frame(maxHeight: .infinity, alignment: .top)
    .padding(.leading, 8)
  }

  private var statsSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Stats")
        .font(.headline)
        .foregroundColor(.white)
        .opacity(0.9)

      Text("Total: \(collectedFish.count)")
        .font(.subheadline)
        .foregroundColor(.white)
        .opacity(0.8)

      Text("Swimming:")
        .font(.caption)
        .foregroundColor(.gray.opacity(0.7))

      Text("\(visibleFish.count)/\(AppConfig.maxSwimmingFish)")
        .font(.caption)
        .foregroundColor(
          visibleFish.count >= AppConfig.maxSwimmingFish
            ? .orange.opacity(0.9) : .green.opacity(0.8))

      Text("Hidden: \(hiddenFish.count)")
        .font(.caption)
        .foregroundColor(.gray.opacity(0.7))
    }
  }

  private func fishGridSection(geometry: GeometryProxy) -> some View {
    ScrollView {
      LazyVGrid(
        columns: Array(
          repeating: GridItem(.flexible()),
          count: columnCount(for: geometry.size.width - 120)),
        spacing: 15
      ) {
        ForEach(collectedFish) { fish in
          FishItemView(
            fish: fish,
            onFishSelected: onFishSelected,
            onVisibilityToggled: onVisibilityToggled,
            showLimitAlert: $showLimitAlert
          )
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: .infinity)
  }

  private var footerSection: some View {
    VStack(spacing: 4) {
      Text("👁️ = Swimming in tank | 👁️‍🗨️ = Hidden from tank")
        .font(.system(size: 10))
        .foregroundColor(.gray)
      Text("Maximum \(AppConfig.maxSwimmingFish) fish can swim at once")
        .font(.system(size: 10))
        .foregroundColor(.orange)
        .padding(.bottom)
    }
  }

  private var contentBackground: some View {
    RoundedRectangle(cornerRadius: 15)
      .fill(.regularMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 15)
          .stroke(Color.white.opacity(0.1), lineWidth: 1)
      )
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }

  private func columnCount(for width: CGFloat) -> Int {
    // Calculate columns based on screen width
    // Assuming each column needs roughly 120 points (item + spacing)
    let availableWidth = width - 40  // Account for padding
    let columnWidth: CGFloat = 120
    let calculatedColumns = Int(availableWidth / columnWidth)

    // Ensure minimum 2 columns and maximum 6 columns
    return max(2, min(6, calculatedColumns))
  }
}

struct FishItemView: View {
  let fish: CollectedFish
  let onFishSelected: (CollectedFish) -> Void
  let onVisibilityToggled: (CollectedFish) -> Bool
  @Binding var showLimitAlert: Bool

  var body: some View {
    VStack {
      fishButton
      visibilityToggleButton
    }
  }

  private var fishButton: some View {
    Button(action: {
      let success = onVisibilityToggled(fish)
      if !success {
        showLimitAlert = true
      }
    }) {
      fishContent
    }
  }

  private var fishContent: some View {
    VStack {
      Text(fish.emoji)
        .font(.title)
        .frame(width: 40, height: 40)
      Text(fish.rarity.rawValue)
        .font(.caption)
        .foregroundColor(fish.rarity.color.opacity(0.9))
      Text(formatDate(fish.dateCaught))
        .font(.system(size: 8))
        .foregroundColor(.gray.opacity(0.7))
    }
    .padding(8)
    .background(fishBackground)
    .opacity(fish.isVisible ? 0.9 : 0.5)
  }

  private var fishBackground: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(.ultraThinMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.white.opacity(0.15), lineWidth: 1)
      )
  }

  private var visibilityToggleButton: some View {
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

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
}
