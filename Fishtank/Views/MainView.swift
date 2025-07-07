//
//  MainView.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    var body: some View {
        Group {
            if supabaseManager.isAuthenticated {
                ContentView()
                    .environmentObject(supabaseManager)
            } else {
                AuthView()
            }
        }
        .onAppear {
            // Check authentication status when app appears
            Task {
                await supabaseManager.checkCurrentUser()
            }
        }
    }
}

#Preview {
    MainView()
} 