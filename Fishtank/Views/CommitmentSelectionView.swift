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
      Color.black.opacity(0.3)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      VStack(spacing: 12) {
        Text("Choose Your Focus Commitment")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .opacity(0.9)
          .padding(.top, 16)

        LazyVStack(spacing: 12) {
          ForEach(FocusCommitment.allCases, id: \.self) { commitment in
            Button(action: {
              onCommitmentSelected(commitment)
              isPresented = false
            }) {
              HStack {
                Text(commitment.emoji)
                  .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                  Text(commitment.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .opacity(0.9)
                  Text(
                    "Reward: \(commitment.lootboxType.emoji) \(commitment.lootboxType.rawValue) Lootbox"
                  )
                  .font(.caption2)
                  .foregroundColor(.gray.opacity(0.8))
                }

                Spacer()
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
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
        }
        .padding(.horizontal, 20)

        .frame(maxHeight: 300)  // Limit the height to ensure it fits in landscape

        Button("Cancel") {
          isPresented = false
        }
        .foregroundColor(.red.opacity(0.8))
        .padding(.bottom, 16)
      }
      .background(
        RoundedRectangle(cornerRadius: 15)
          .fill(.regularMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 15)
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
          )
      )
      .padding(.horizontal, 30)
      .padding(.vertical, 20)
    }
  }
}
