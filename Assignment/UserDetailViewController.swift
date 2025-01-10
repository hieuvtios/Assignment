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
    override func viewDidLoad() {
        super.viewDidLoad()
        if let user = user {
            loadUserDetails(for: user)
        }
    }

    func loadUserDetails(for user: User) {
        // Check if user details are cached in Core Data
            // If not cached, fetch from the API
            fetchUserDetails(for: user)
        
    }

    func fetchCachedUser(for login: String) -> UserEntity? {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "login == %@", login)

        do {
            let results = try CoreDataStack.shared.context.fetch(fetchRequest)
            if let cachedUser = results.first {
                return cachedUser
            }
        } catch {
            print("Failed to fetch user from Core Data: \(error)")
        }

        return nil
    }

    func fetchUserDetails(for user: User) {
        guard let url = URL(string: "https://api.github.com/users/\(user.login)") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
        // Update labels with default fallback values
        lblUsername.text = userEntity.login
        lblLocation.text = userEntity.location ?? "Unknown location"
        lblFollower.text = "\(userEntity.followers)"
        lblFollowing.text = "\(userEntity.following)"
        lblBlog.text = userEntity.blog?.isEmpty == false ? userEntity.blog : "No blog available"

        // Update the avatar image with a placeholder if needed
        updateAvatarImage(with: userEntity.avatar_url)
    }

    // Helper function to update the avatar image
    private func updateAvatarImage(with urlString: String?) {
        if let urlString = urlString, let avatarURL = URL(string: urlString) {
            imgAvatar.sd_setImage(with: avatarURL, placeholderImage: UIImage(named: "placeholder"))
        } else {
            imgAvatar.image = UIImage(named: "placeholder")
        }
    }
 

    private func showDataChangedAlert() {
        let alert = UIAlertController(
            title: "Data Updated",
            message: "The user details have been updated. Please review the changes.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    private func showDataFailedAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "Not found!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


 
}
