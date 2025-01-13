//
//  Welcome.swift
//  Assignment
//
//  Created by Hieu Vu on 1/8/25.
//

import Foundation
import Combine
import UIKit
import CoreData
import Alamofire

class GitHubService {
    let perPage = 20
    var since = 0
    let context = CoreDataStack.shared
    let coreDataStack = CoreDataStack.shared
    static let shared = GitHubService()
    
    func fetchGithubUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "token \(Constants.token)"
        ]
        
        AF.request(Constants.serverAPI, headers: headers)
            .responseDecodable(of: [User].self) { response in
                switch response.result {
                case .success(let users):
                    completion(.success(users))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func saveUsersToCoreData(_ users: [User], completion: @escaping (Result<Void, Error>) -> Void) {
        let context = CoreDataStack.shared.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.perform {
            do {
                // Step 1: Fetch all existing user IDs in one query
                let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "UserEntity")
                fetchRequest.propertiesToFetch = ["id"]
                fetchRequest.resultType = .dictionaryResultType
                
                let results = try context.fetch(fetchRequest)
                let existingIDs = Set(results.compactMap { $0["id"] as? Int64 })
                
                // Step 2: Filter out users that already exist
                let newUsers = users.filter { !existingIDs.contains(Int64($0.id)) }
                
                // Step 3: Use NSBatchInsertRequest for faster inserts
                let batchInsert = NSBatchInsertRequest(entity: UserEntity.entity(), objects: newUsers.map { user in
                    [
                        "id": Int64(user.id),
                        "login": user.login,
                        "avatar_url": user.avatar_url,
                        "html_url": user.html_url,
                        "insertDate": Date()
                    ] as [String: Any]
                })
                
                // Step 4: Execute the batch insert
                try context.execute(batchInsert)
                try context.save()
                
                // Step 5: Call completion with success
                completion(.success(()))
            } catch {
                // Handle errors
                completion(.failure(error))
            }
        }
    }

    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        let urlString = "https://api.github.com/users"
        let parameters: [String: Any] = [
            "per_page": perPage,
            "since": since
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": "token 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"
        ]
        
        AF.request(urlString, method: .get, parameters: parameters, headers: headers)
            .validate()
            .responseDecodable(of: [User].self) { [weak self] response in
                switch response.result {
                case .success(let users):
                    if let lastUser = users.last {
                        self?.since = lastUser.id
                    }
                    completion(.success(users))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // New method combining network request and CoreData operations
    func fetchAndSaveUserDetails(for user: User, completion: @escaping (Result<UserEntity, Error>) -> Void) {
        let urlString = "https://api.github.com/users/\(user.login)"
        let headers: HTTPHeaders = [
            "Authorization": "token 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"
        ]
        
        AF.request(urlString, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: DetailedUser.self) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let userDetails):
                    do {
                        let userEntity = try self.updateUserInCoreData(with: userDetails, for: user)
                        completion(.success(userEntity))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // Helper method for CoreData operations
    private func updateUserInCoreData(with details: DetailedUser, for user: User) throws -> UserEntity {
        let context = CoreDataStack.shared.context
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "login == %@", user.login)
        
        let userEntity: UserEntity
        if let existingUser = try context.fetch(fetchRequest).first {
            userEntity = existingUser
        } else {
            userEntity = UserEntity(context: context)
            userEntity.login = user.login
        }
        
        userEntity.blog = details.blog ?? ""
        userEntity.followers = Int64(details.followers ?? 0)
        userEntity.following = Int64(details.following ?? 0)
        userEntity.location = details.location ?? ""
        
        try context.save()
        return userEntity
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
}
