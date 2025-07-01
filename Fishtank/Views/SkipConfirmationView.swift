//
//  SkipConfirmationView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct SkipConfirmationView: View {
  @Binding var isPresented: Bool
  let commitment: FocusCommitment
  @ObservedObject var commitmentManager: CommitmentManager
  let onSkipConfirmed: (FocusCommitment) -> Void

  @State private var showError = false

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          if !commitmentManager.isPurchasing {
            isPresented = false
          }
        }

      VStack(spacing: 16) {
        // Header
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            Image(systemName: "creditcard.fill")
              .font(.title3)
              .foregroundColor(.white.opacity(0.9))

            Text("Skip Session")
              .font(.system(.headline, design: .rounded))
              .fontWeight(.semibold)
              .foregroundColor(.white)
          }

          // Current commitment
          HStack(spacing: 6) {
            Text(commitment.emoji)
              .font(.headline)
              .padding(6)
              .background(
                Circle()
                  .fill(.ultraThinMaterial)
              )
            Text(commitment.rawValue)
              .font(.system(.subheadline, design: .rounded))
              .foregroundColor(.yellow.opacity(0.9))
          }
        }
        .padding(.top, 6)

        // Cost information
        VStack(spacing: 12) {
          HStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
              .font(.title3)
              .foregroundColor(.green.opacity(0.9))

            Text("Skip Cost")
              .font(.system(.subheadline, design: .rounded))
              .foregroundColor(.white.opacity(0.8))

            Spacer()

            if commitmentManager.isLoadingProducts {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(0.7)
            } else {
              Text(commitmentManager.getSkipPrice(for: commitment))
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.green)
            }
          }

          if !commitmentManager.isLoadingProducts {
            let price = commitmentManager.getSkipPrice(for: commitment)
            if price != "Loading..." {
              HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                  .font(.caption)
                  .foregroundColor(.yellow.opacity(0.8))
                Text(
                  "You'll receive a \(commitment.lootboxType.emoji) \(commitment.lootboxType.rawValue) lootbox!"
                )
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.yellow.opacity(0.8))
                .multilineTextAlignment(.leading)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 2)
            }
          }
        }
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )

        // Buttons
        VStack(spacing: 8) {
          Button(action: {
            Task {
              if let skippedCommitment = await commitmentManager.skipCommitmentWithPurchase() {
                onSkipConfirmed(skippedCommitment)
                isPresented = false
              } else {
                showError = true
              }
            }
          }) {
            HStack(spacing: 8) {
              if commitmentManager.isPurchasing {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  .scaleEffect(0.7)
              } else {
                Image(systemName: "creditcard.fill")
                  .font(.subheadline)
                Text("Purchase Skip")
                  .font(.system(.subheadline, design: .rounded))
              }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.7))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            )
          }
          .disabled(commitmentManager.isPurchasing || commitmentManager.isLoadingProducts)

          Button(action: {
            if !commitmentManager.isPurchasing {
              isPresented = false
            }
          }) {
            HStack(spacing: 6) {
              Image(systemName: "xmark.circle")
                .font(.subheadline)
              Text("Cancel")
                .font(.system(.subheadline, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            )
          }
          .disabled(commitmentManager.isPurchasing)
        }
      }
      .padding(16)
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
    .task {
      // Ensure products are loaded when view appears
      await commitmentManager.ensureProductsLoaded()
    }
    .alert("Purchase Failed", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(commitmentManager.getPurchaseError() ?? "An unknown error occurred")
    }
  }
}
