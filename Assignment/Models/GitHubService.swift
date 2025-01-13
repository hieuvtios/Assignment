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
    private let perPage = 20
    var since = 0
    private let context = CoreDataStack.shared
    let coreDataStack = CoreDataStack.shared
    
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
        context.perform {
            for user in users {
                // Check if user already exists to prevent duplicates
                let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %d", user.id)

                do {
                    let count = try context.count(for: fetchRequest)
                    if count == 0 {
                        let newUser = UserEntity(context: context)
                        newUser.insertDate = Date()
                        newUser.id = Int64(user.id)
                        newUser.login = user.login
                        newUser.avatar_url = user.avatar_url
                        newUser.html_url = user.html_url
                    }
                } catch {
                    completion(.failure(error))
                    return
                }
            }

            do {
                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // Fetch users from GitHub API
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        let urlString = "https://api.github.com/users"
        let parameters: [String: Any] = [
            "per_page": perPage,
            "since": since
        ]
        
        // Custom headers
        let headers: HTTPHeaders = [
            "Authorization": "token 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"
        ]
        
        AF.request(urlString, method: .get, parameters: parameters, headers: headers)
            .validate() // Automatically validates the status code (200-299) and content type
            .responseDecodable(of: [User].self) { [weak self] response in
                switch response.result {
                case .success(let users):
                    // Update 'since' for pagination
                    if let lastUser = users.last {
                        self?.since = lastUser.id
                    }
                    completion(.success(users))
                case .failure(let error):
                    completion(.failure(error.localizedDescription as! Error))
                }
            }
    }
    // Fetch detailed user info
    func fetchUserDetails(username: String, completion: @escaping (Result<DetailedUser, Error>) -> Void) {
        let urlString = "https://api.github.com/users/\(username)"
        
        AF.request(urlString, method: .get)
            .validate() // Automatically validates the status code (200-299) and content type
            .responseDecodable(of: DetailedUser.self) { response in
                switch response.result {
                case .success(let detailedUser):
                    completion(.success(detailedUser))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
}
