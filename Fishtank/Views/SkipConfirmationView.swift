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
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    if !commitmentManager.isPurchasing {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Skip Commitment?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(commitment.emoji) \(commitment.rawValue)")
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
                
                // Cost information
                VStack(spacing: 12) {
                    HStack {
                        Text("Skip Cost:")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        if commitmentManager.isLoadingProducts {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(0.8)
                        } else {
                            Text(commitmentManager.getSkipPrice(for: commitment))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if !commitmentManager.isLoadingProducts {
                        let price = commitmentManager.getSkipPrice(for: commitment)
                        if price != "Loading..." {
                            Text("💰 Pay \(price) to instantly complete your focus session and earn the \(commitment.lootboxType.emoji) \(commitment.lootboxType.rawValue) lootbox!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 12) {
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
                        HStack {
                            if commitmentManager.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("💳 Purchase Skip")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green.opacity(0.7))
                        )
                    }
                    .disabled(commitmentManager.isPurchasing || commitmentManager.isLoadingProducts)
                    
                    Button(action: {
                        if !commitmentManager.isPurchasing {
                            isPresented = false
                        }
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.3))
                            )
                    }
                    .disabled(commitmentManager.isPurchasing)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
        }
        .task {
            // Ensure products are loaded when view appears
            await commitmentManager.ensureProductsLoaded()
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(commitmentManager.getPurchaseError() ?? "An unknown error occurred")
        }
    }
} 