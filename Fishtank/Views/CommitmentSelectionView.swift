//
//  CommitmentSelectionView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

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

      VStack(spacing: 4) {
        // Header
        HStack {
          Image(systemName: "target")
            .font(.title3)
            .foregroundColor(.white.opacity(0.9))

          Text("Choose Focus Duration")
            .font(.system(.headline, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .opacity(0.9)
        }
        .padding(.top, 16)
        .padding(.bottom, 6)

        // Commitment Options
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
          ForEach(FocusCommitment.allCases, id: \.self) { commitment in
            Button(action: {
              onCommitmentSelected(commitment)
              isPresented = false
            }) {
              HStack(spacing: 6) {
                // Duration emoji in circle
                Text(commitment.emoji)
                  .font(.headline)
                  .padding(6)
                  .background(
                    Circle()
                      .fill(.ultraThinMaterial)
                  )

                // Commitment details
                VStack(alignment: .leading, spacing: 2) {
                  Text(commitment.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(0.9)

                  HStack(spacing: 2) {
                    Image(systemName: "gift")
                      .font(.caption2)
                      .foregroundColor(.yellow.opacity(0.8))
                    Text("\(commitment.lootboxType.emoji) \(commitment.lootboxType.rawValue)")
                      .font(.system(.caption2, design: .rounded))
                      .foregroundColor(.yellow.opacity(0.8))
                  }
                }

                Spacer()

                // Arrow indicator
                Image(systemName: "chevron.right")
                  .font(.caption2)
                  .foregroundColor(.white.opacity(0.4))
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
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
        .padding(.horizontal, 12)

        // Cancel button
        Button(action: {
          isPresented = false
        }) {
          HStack(spacing: 3) {
            Image(systemName: "xmark.circle")
              .font(.subheadline)
            Text("Cancel")
              .font(.system(.subheadline, design: .rounded))
          }
          .foregroundColor(.white.opacity(0.7))
          .padding(.vertical, 8)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
      }
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
  }
}
