//
//  ExportView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI
import UIKit

struct ExportView: View {
    let exportData: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(exportData)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Fish Collection Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        let activityController = UIActivityViewController(
                            activityItems: [exportData],
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first
                        {
                            window.rootViewController?.present(activityController, animated: true)
                        }
                    }
                }
            }
        }
    }
} 