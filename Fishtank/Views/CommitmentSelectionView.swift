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

        // Commitment Options - 4 Horizontal Squares
        HStack(spacing: 8) {
          ForEach(FocusCommitment.allCases, id: \.self) { commitment in
            Button(action: {
              onCommitmentSelected(commitment)
              isPresented = false
            }) {
              VStack(spacing: 8) {
                // Duration icon
                Image(systemName: commitment.iconName)
                  .font(.title2)
                  .foregroundColor(.white)

                // Commitment duration
                Text(commitment.rawValue)
                  .font(.system(.subheadline, design: .rounded))
                  .foregroundColor(.white)
                  .opacity(0.9)
                  .multilineTextAlignment(.center)

                // Lootbox type
                VStack(spacing: 2) {
                  Text(commitment.lootboxType.emoji)
                    .font(.caption)
                    .foregroundColor(.yellow.opacity(0.8))
                  Text(commitment.lootboxType.rawValue)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.yellow.opacity(0.8))
                }
              }
              .frame(maxWidth: .infinity)
              .frame(height: 100)
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
          HStack(spacing: 4) {
            Image(systemName: "xmark.circle")
              .font(.caption)
            Text("Cancel")
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
        .padding(.horizontal, 12)
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
