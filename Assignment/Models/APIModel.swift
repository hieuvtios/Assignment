//
//  APIModel.swift
//  Assignment
//
//  Created by Hieu Vu on 1/8/25.
//

import Foundation
import Alamofire

class APIService {
    init(){}
    
    func fetchGithubUsers(completion: @escaping (Result<[GithubUser], Error>) -> Void) {
        AF.request(Constants.serverAPI).responseDecodable(of: [GithubUser].self) { response in
            switch response.result {
            case .success(let users):
                completion(.success(users))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
