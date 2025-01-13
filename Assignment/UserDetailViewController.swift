//
//  UserDetailViewController.swift
//  Assignment
//
//  Created by Hieu Vu on 1/9/25.
//

import UIKit
import CoreData

class UserDetailViewController: UIViewController {
    // MARK: - Properties
    var user: User?
    private let coreDataContext = CoreDataStack.shared.context
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - IBOutlets
    @IBOutlet private weak var lblBlog: UILabel!
    @IBOutlet private weak var lblUsername: UILabel!
    @IBOutlet private weak var imgAvatar: UIImageView!
    @IBOutlet private weak var lblLocation: UILabel!
    @IBOutlet private weak var lblFollowing: UILabel!
    @IBOutlet private weak var lblFollower: UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserDetails()
    }
}

// MARK: - Setup
private extension UserDetailViewController {
    func setupUI() {
        setupActivityIndicator()
        setupImageView()
    }
    
    func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func setupImageView() {
        imgAvatar.makeRounded()
    }
}

// MARK: - Data Loading
private extension UserDetailViewController {
    func loadUserDetails() {
        guard let user = user else { return }
        
        startLoading()
        fetchUserDetails(for: user)
    }
    
    func fetchUserDetails(for user: User) {
        let urlString = "https://api.github.com/users/\(user.login)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token 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",
                        forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.stopLoading()
            }
            
            if let error = error {
                self.handleError(error)
                return
            }
            
            guard let data = data else {
                self.handleError(NSError(domain: "", code: -1))
                return
            }
            
            self.processUserDetails(data, for: user)
        }.resume()
    }
    
    func processUserDetails(_ data: Data, for user: User) {
        do {
            let userDetails = try JSONDecoder().decode(DetailedUser.self, from: data)
            let userEntity = try updateCoreData(with: userDetails, for: user)
            
            DispatchQueue.main.async {
                self.updateUI(with: userEntity)
            }
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Core Data
private extension UserDetailViewController {
    func updateCoreData(with details: DetailedUser, for user: User) throws -> UserEntity {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "login == %@", user.login)
        
        let userEntity: UserEntity
        if let existingUser = try coreDataContext.fetch(fetchRequest).first {
            userEntity = existingUser
        } else {
            userEntity = UserEntity(context: coreDataContext)
            userEntity.login = user.login
        }
        
        userEntity.blog = details.blog ?? ""
        userEntity.followers = Int64(details.followers ?? 0)
        userEntity.following = Int64(details.following ?? 0)
        userEntity.location = details.location ?? ""
        
        try coreDataContext.save()
        return userEntity
    }
}

// MARK: - UI Updates
private extension UserDetailViewController {
    func updateUI(with userEntity: UserEntity) {
        lblUsername.text = userEntity.login
        lblLocation.text = userEntity.location ?? "Unknown location"
        lblFollower.text = "\(userEntity.followers)"
        lblFollowing.text = "\(userEntity.following)"
        lblBlog.text = userEntity.blog?.isEmpty == false ? userEntity.blog : "No blog available"
        
        updateAvatar(with: userEntity.avatar_url)
    }
    
    func updateAvatar(with urlString: String?) {
        imgAvatar?.sd_setImage(
            with: URL(string: urlString ?? ""),
            placeholderImage: UIImage(named: "placeholder")
        )
    }
}

// MARK: - Loading State
private extension UserDetailViewController {
    func startLoading() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    func stopLoading() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }
}

// MARK: - Error Handling
private extension UserDetailViewController {
    func handleError(_ error: Error) {
        print("Error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.showErrorAlert()
        }
    }
    
    func showErrorAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to load user details. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Public Interface
extension UserDetailViewController {
    func configure(with user: User) {
        self.user = user
    }
}
