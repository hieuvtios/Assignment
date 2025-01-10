//
//  User 2.swift
//  Assignment
//
//  Created by Hieu Vu on 1/9/25.
//


struct User: Codable, Identifiable {
    let id: Int
    let login: String
    let avatar_url: String
    let html_url: String
}
struct DetailedUser: Codable {
    let login: String
    let id: Int?
    let avatar_url: String?
    let html_url: String?
    let followers: Int?
    let following: Int?
    let location: String?
    let blog: String?
}
