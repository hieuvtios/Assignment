//
//  UserDetailViewController.swift
//  Assignment
//
//  Created by Hieu Vu on 1/9/25.
//

import UIKit
import Alamofire

class UserDetailViewController: UIViewController {
    // MARK: - Properties
    var user: User?
    private let service = GitHubService.shared
    
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
        service.fetchAndSaveUserDetails(for: user) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.stopLoading()
                
                switch result {
                case .success(let userEntity):
                    self.updateUI(with: userEntity)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
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
        showErrorAlert()
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
