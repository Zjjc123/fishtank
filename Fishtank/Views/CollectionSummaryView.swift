//
//  CollectionSummaryView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

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