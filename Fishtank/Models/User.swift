//
//  User.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let createdAt: Date
    let updatedAt: Date
    let emailConfirmed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case emailConfirmed = "email_confirmed_at"
    }
    
    init(id: String, email: String, createdAt: Date, updatedAt: Date, emailConfirmed: Bool = false) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.emailConfirmed = emailConfirmed
    }
}

struct UserProfile: Codable {
    let id: String
    let email: String
    let username: String?
    let totalFocusTime: TimeInterval
    let totalFishCaught: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case totalFocusTime = "total_focus_time"
        case totalFishCaught = "total_fish_caught"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 