//
//  BottomActionBarView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct BottomActionBarView: View {
  let isCommitmentActive: Bool
  let onFocusTapped: () -> Void
  let onCancelTapped: () -> Void
  let onCollectionTapped: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      if !isCommitmentActive {
        Button(action: onFocusTapped) {
          HStack(spacing: 8) {
            Image(systemName: "target")
              .font(.title3)
            Text("Focus")
              .font(.headline)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.ultraThinMaterial.opacity(0.4))
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(Color.white.opacity(0.2), lineWidth: 1)
              )
          )
        }
      } else {
        Button(action: onCancelTapped) {
          HStack(spacing: 8) {
            Image(systemName: "xmark.circle")
              .font(.title3)
            Text("Cancel")
              .font(.headline)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color.red.opacity(0.2))
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(Color.red.opacity(0.2), lineWidth: 1)
              )
          )
        }
      }

      Button(action: onCollectionTapped) {
        HStack(spacing: 8) {
          Image(systemName: "fish")
            .font(.title3)
          Text("Collection")
            .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial.opacity(0.4))
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )
      }
    }
    .padding(.horizontal, 25)
    .padding(.bottom, 30)
  }
}

#Preview {
  BottomActionBarView(
    isCommitmentActive: false,
    onFocusTapped: {},
    onCancelTapped: {},
    onCollectionTapped: {}
  )
  .background(Color.blue)
}
