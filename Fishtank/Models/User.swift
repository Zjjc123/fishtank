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
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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