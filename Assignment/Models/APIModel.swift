//
//  APIModel.swift
//  Assignment
//
//  Created by Hieu Vu on 1/8/25.
//

import Foundation
import Alamofire
import CoreData
class APIService {
    let coreDataStack = CoreDataStack.shared
    
    init(){}
    
    func fetchGithubUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        AF.request(Constants.serverAPI).responseDecodable(of: [User].self) { response in
            switch response.result {
            case .success(let users):
                completion(.success(users))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}

