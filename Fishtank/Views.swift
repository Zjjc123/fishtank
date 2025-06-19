//
//  Views.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

// MARK: - Clock Display
struct ClockDisplayView: View {
  let currentTime: Date

  var body: some View {
    VStack(spacing: 8) {
      Text(timeString(from: currentTime))
        .font(.system(size: 48, weight: .bold, design: .monospaced))
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.5), radius: 2)

      Text(dateString(from: currentTime))
        .font(.headline)
        .foregroundColor(.white.opacity(0.8))
        .shadow(color: .black.opacity(0.5), radius: 1)
    }
    .padding(.top, 50)
  }

  private func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }

  private func dateString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }
}

// MARK: - Commitment Progress
struct CommitmentProgressView: View {
  let commitment: FocusCommitment
  let progress: Double
  let timeRemaining: TimeInterval

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text("\(commitment.emoji) \(commitment.rawValue)")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
        Text(formatCommitmentTime(timeRemaining))
          .font(.headline)
          .foregroundColor(.yellow)
      }

      ProgressView(value: progress)
        .progressViewStyle(LinearProgressViewStyle(tint: .green))
        .scaleEffect(x: 1, y: 2, anchor: .center)
    }
    .padding(.horizontal, 30)
    .padding(.top, 20)
  }

  private func formatCommitmentTime(_ time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = (Int(time) % 3600) / 60
    let seconds = Int(time) % 60

    if hours > 0 {
      return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }
}

// MARK: - Stats Display
struct StatsDisplayView: View {
  let fishCount: Int
  let timeSpent: TimeInterval
  let giftBoxCount: Int
  let lootboxCount: Int

  var body: some View {
    HStack(spacing: 20) {
      StatItemView(value: "\(fishCount)", label: "Fish Collected", color: .white)
      StatItemView(value: formatTime(timeSpent), label: "Focus Time", color: .white)
      StatItemView(value: "\(giftBoxCount)", label: "Gift Boxes", color: .yellow)
      StatItemView(value: "\(lootboxCount)", label: "Lootboxes", color: .purple)
    }
    .padding(.bottom, 20)
  }

  private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}

struct StatItemView: View {
  let value: String
  let label: String
  let color: Color

  var body: some View {
    VStack {
      Text(value)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(color)
      Text(label)
        .font(.caption)
        .foregroundColor(.white.opacity(0.8))
    }
  }
}

// MARK: - Collection Summary
struct CollectionSummaryView: View {
  let fishCollection: [FishRarity: Int]

  var body: some View {
    if !fishCollection.isEmpty {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
        ForEach(FishRarity.allCases, id: \.self) { rarity in
          VStack {
            Text(rarity.emojis.first ?? "🐟")
              .font(.title2)
            Text("\(fishCollection[rarity] ?? 0)")
              .font(.caption)
              .foregroundColor(rarity.color)
              .fontWeight(.bold)
            Text(rarity.rawValue)
              .font(.system(size: 8))
              .foregroundColor(.white.opacity(0.6))
          }
        }
      }
      .padding(.bottom, 10)
    }
  }
}

// MARK: - Fish Collection Management
struct FishCollectionView: View {
  let collectedFish: [CollectedFish]
  let onFishSelected: (CollectedFish) -> Void
  @Binding var isPresented: Bool

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

        ScrollView {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
            ForEach(collectedFish) { fish in
              Button(action: {
                onFishSelected(fish)
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
              }
            }
          }
          .padding()
        }

        Text("Tap a fish to add it to your swimming display!")
          .font(.caption)
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

// MARK: - Commitment Selection
struct CommitmentSelectionView: View {
  @Binding var isPresented: Bool
  let onCommitmentSelected: (FocusCommitment) -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      VStack(spacing: 20) {
        Text("Choose Your Focus Commitment")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.top)

        ForEach(FocusCommitment.allCases, id: \.self) { commitment in
          Button(action: {
            onCommitmentSelected(commitment)
            isPresented = false
          }) {
            HStack {
              Text(commitment.emoji)
                .font(.title)

              VStack(alignment: .leading) {
                Text(commitment.rawValue)
                  .font(.headline)
                  .foregroundColor(.white)
                Text(
                  "Reward: \(commitment.lootboxType.emoji) \(commitment.lootboxType.rawValue) Lootbox"
                )
                .font(.caption)
                .foregroundColor(.gray)
              }

              Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.8))
            .cornerRadius(10)
          }
        }

        Button("Cancel") {
          isPresented = false
        }
        .foregroundColor(.red)
        .padding(.bottom)
      }
      .padding()
      .background(Color.black.opacity(0.9))
      .cornerRadius(15)
      .padding(.horizontal, 30)
    }
  }
}

// MARK: - Reward Notification
struct RewardNotificationView: View {
  let message: String
  let isVisible: Bool

  var body: some View {
    if isVisible {
      VStack {
        Text(message)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding()
          .background(Color.green.opacity(0.8))
          .cornerRadius(10)
          .shadow(radius: 5)
      }
      .transition(.scale.combined(with: .opacity))
    }
  }
}

// MARK: - Game Item Views
struct SwimmingFishView: View {
  let fish: SwimmingFish

  var body: some View {
    ZStack {
      Ellipse()
        .fill(fish.color)
        .frame(width: fish.size, height: fish.size * 0.6)

      Triangle()
        .fill(fish.color.opacity(0.8))
        .frame(width: fish.size * 0.4, height: fish.size * 0.4)
        .offset(x: fish.direction > 0 ? -fish.size * 0.4 : fish.size * 0.4)

      Circle()
        .fill(.white)
        .frame(width: fish.size * 0.2)
        .overlay(
          Circle()
            .fill(.black)
            .frame(width: fish.size * 0.1)
        )
        .offset(x: fish.direction > 0 ? fish.size * 0.15 : -fish.size * 0.15, y: -fish.size * 0.1)

      Text(fish.emoji)
        .font(.system(size: fish.size * 0.3))
        .offset(y: fish.size * 0.1)
    }
    .scaleEffect(x: fish.direction > 0 ? 1 : -1, y: 1)
    .shadow(color: .black.opacity(0.3), radius: 2)
  }
}

struct GiftBoxView: View {
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.brown)
        .frame(width: 40, height: 40)

      Rectangle()
        .fill(Color.red)
        .frame(width: 40, height: 6)

      Rectangle()
        .fill(Color.red)
        .frame(width: 6, height: 40)

      Text("🎀")
        .font(.title3)
        .offset(y: -20)
    }
    .scaleEffect(isAnimating ? 1.1 : 1.0)
    .animation(
      Animation.easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true),
      value: isAnimating
    )
    .onAppear {
      isAnimating = true
    }
    .shadow(color: .yellow.opacity(0.5), radius: 8)
  }
}

struct LootboxView: View {
  let type: LootboxType
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .fill(type.color.opacity(0.8))
        .frame(width: 50, height: 50)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(type.color, lineWidth: 3)
        )

      Text(type.emoji)
        .font(.title)
    }
    .scaleEffect(isAnimating ? 1.15 : 1.0)
    .animation(
      Animation.easeInOut(duration: 0.8)
        .repeatForever(autoreverses: true),
      value: isAnimating
    )
    .onAppear {
      isAnimating = true
    }
    .shadow(color: type.color.opacity(0.7), radius: 10)
  }
}

// MARK: - Shapes
struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
    return path
  }
}
