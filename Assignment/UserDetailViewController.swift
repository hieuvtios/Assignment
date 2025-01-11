//
//  UserDetailViewController.swift
//  Assignment
//
//  Created by Hieu Vu on 1/9/25.
//

import UIKit
import CoreData

class UserDetailViewController: UIViewController {
    var user: User? // Pass the selected user
    @IBOutlet weak var lblBlog: UILabel!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblFollowing: UILabel!
    @IBOutlet weak var lblFollower: UILabel!
    
    // Add Activity Indicator
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActivityIndicator()

        if let user = user {
            loadUserDetails(for: user)
        }
    }

    private func setupActivityIndicator() {
        // Configure and add the activity indicator to the center of the view
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Center the activity indicator in the view
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func loadUserDetails(for user: User) {
        startLoading() // Show activity indicator
        fetchUserDetails(for: user)
    }

    func fetchUserDetails(for user: User) {
        guard let url = URL(string: "https://api.github.com/users/\(user.login)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token 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", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.stopLoading() // Hide activity indicator
            }

            guard let data = data, error == nil else {
                print("Failed to fetch user details: \(error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    self.showDataFailedAlert()
                }
                return
            }

            do {
                let userDetails = try JSONDecoder().decode(DetailedUser.self, from: data)
                
                // Fetch or create the Core Data entity
                let context = CoreDataStack.shared.context
                let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "login == %@", user.login)

                let userEntity: UserEntity
                if let existingUser = try context.fetch(fetchRequest).first {
                    // Update existing user
                    userEntity = existingUser
                } else {
                    // Create a new user entity
                    userEntity = UserEntity(context: context)
                    userEntity.login = user.login
                }

                // Update user details
                userEntity.blog = userDetails.blog ?? ""
                userEntity.followers = Int64(userDetails.followers ?? 0)
                userEntity.following = Int64(userDetails.following ?? 0)
                userEntity.location = userDetails.location ?? ""

                // Save the context
                try context.save()

                // Update the UI on the main thread
                DispatchQueue.main.async {
                    self.updateUI(with: userEntity)
                }

            } catch {
                print("Failed to process user details: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showDataFailedAlert()
                }
            }
        }
        task.resume()
    }

    func updateUI(with userEntity: UserEntity) {
        lblUsername.text = userEntity.login
        lblLocation.text = userEntity.location ?? "Unknown location"
        lblFollower.text = "\(userEntity.followers)"
        lblFollowing.text = "\(userEntity.following)"
        lblBlog.text = userEntity.blog?.isEmpty == false ? userEntity.blog : "No blog available"

        // Update the avatar image with a placeholder if needed
        imgAvatar?.sd_setImage(with: URL(string: userEntity.avatar_url ?? "")) { (image, error, cache, urls) in
            if (error != nil) {
                self.imgAvatar.image = UIImage(named: "placeholder")
            } else {
                self.imgAvatar.image = image
            }
        }
        imgAvatar.makeRounded()
    }

    private func showDataFailedAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to load user details. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func startLoading() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false // Disable user interaction while loading
    }

    private func stopLoading() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true // Enable user interaction after loading
    }
}
