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
    
    /// Fetches a list of GitHub users from the API.
    /// - Parameter completion: A closure called with the result, either a list of users or an error.
    func fetchGithubUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        
        // Use a header when testing the GitHub API.
        let headers: HTTPHeaders = [
            "Authorization": "token \(Constants.token)"
        ]
        
        
        AF.request(Constants.serverAPI, headers: nil)
            .responseDecodable(of: [User].self) { response in
                switch response.result {
                case .success(let users):
                    completion(.success(users))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    /// Saves a list of GitHub users to CoreData, skipping users that already exist.
    /// - Parameters:
    ///   - users: A list of users to save.
    ///   - completion: A closure called with the result, either success or an error.
    func saveUsersToCoreData(_ users: [User], completion: @escaping (Result<Void, Error>) -> Void) {
        let context = CoreDataStack.shared.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.perform {
            do {
                // Fetch existing user IDs to prevent duplicates.
                let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "UserEntity")
                fetchRequest.propertiesToFetch = ["id"]
                fetchRequest.resultType = .dictionaryResultType
                
                let results = try context.fetch(fetchRequest)
                let existingIDs = Set(results.compactMap { $0["id"] as? Int64 })
                
                // Filter out already existing users.
                let newUsers = users.filter { !existingIDs.contains(Int64($0.id)) }
                
                guard !newUsers.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                // Insert new users into CoreData using batch insert.
                let batchInsert = NSBatchInsertRequest(entity: UserEntity.entity(), objects: newUsers.map { user in
                    [
                        "id": Int64(user.id),
                        "login": user.login,
                        "avatar_url": user.avatar_url,
                        "html_url": user.html_url,
                        "insertDate": Date()
                    ] as [String: Any]
                })
                
                let result = try context.execute(batchInsert)
                
                if let batchInsertResult = result as? NSBatchInsertResult, batchInsertResult.result as? Bool == true {
                    try context.save()
                    completion(.success(()))
                } else {
                    let error = NSError(domain: "CoreDataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Batch insert failed"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Fetches a paginated list of GitHub users.
    /// - Parameter completion: A closure called with the result, either a list of users or an error.
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        let urlString = "https://api.github.com/users"
        let parameters: [String: Any] = [
            "per_page": perPage,
            "since": since
        ]
        // Use a header when testing the GitHub API.
        let headers: HTTPHeaders = [
            "Authorization": "token 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"
        ]
        
        AF.request(urlString, method: .get, parameters: parameters, headers: nil)
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
    
    /// Fetches detailed information about a GitHub user and saves it to CoreData.
    /// - Parameters:
    ///   - user: The GitHub user to fetch details for.
    ///   - completion: A closure called with the result, either a UserEntity or an error.
    func fetchAndSaveUserDetails(for user: User, completion: @escaping (Result<UserEntity, Error>) -> Void) {
        let urlString = "https://api.github.com/users/\(user.login)"
        // use header when testing API Github
        let headers: HTTPHeaders = [
            "Authorization": "token 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"
        ]
        
        AF.request(urlString, method: .get, headers: nil)
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
    
    /// Updates or creates a GitHub user record in CoreData.
    /// - Parameters:
    ///   - details: The detailed user data from the API.
    ///   - user: The basic user data.
    /// - Returns: The saved UserEntity.
    /// - Throws: An error if the save operation fails.
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


