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
                                Text("Reward: \(commitment.lootboxType.emoji) \(commitment.lootboxType.rawValue) Lootbox")
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