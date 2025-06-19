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