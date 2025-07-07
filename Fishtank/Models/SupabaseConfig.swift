//
//  SupabaseConfig.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

struct SupabaseConfig {
    // MARK: - Configuration
    // Replace these with your actual Supabase credentials
    static let supabaseURL = "https://gasthugweowhkyrpitgi.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdhc3RodWd3ZW93aGt5cnBpdGdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4NTg2MDAsImV4cCI6MjA2NzQzNDYwMH0.Je9AXO_680kdL7Xnp6mjAjOz4EV8YJLJf-kI5SYAH_A"
    
    // MARK: - Validation
    static var isValid: Bool {
        return !supabaseURL.contains("https://gasthugweowhkyrpitgi.supabase.co") && 
               !supabaseAnonKey.contains("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdhc3RodWd3ZW93aGt5cnBpdGdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4NTg2MDAsImV4cCI6MjA2NzQzNDYwMH0.Je9AXO_680kdL7Xnp6mjAjOz4EV8YJLJf-kI5SYAH_A")
    }
    
    // MARK: - Error Messages
    static var configurationError: String {
        return "Supabase configuration is missing. Please update SupabaseConfig.swift with your credentials."
    }
} 