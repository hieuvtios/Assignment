//
//  ViewController.swift
//  Assignment
//
//  Created by Hieu Vu on 1/8/25.
//

import UIKit
import CoreData
import SDWebImage
import Network // Import Network framework

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UITableViewDataSourcePrefetching, NSFetchedResultsControllerDelegate {
    
    private let monitor = NWPathMonitor() // Network monitor instance
    private let queue = DispatchQueue(label: "NetworkMonitor") // Background queue for monitoring

    var githubUsers: [User] = []
    private var fetchedResultsController: NSFetchedResultsController<UserEntity>!
    private let service = GitHubService()
    private let context = CoreDataStack.shared
    private var isLoading = false
    private var currentFetchOffset = 0
    var isInitialLoad = true

    @IBOutlet weak var tblGithubUsers: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tblGithubUsers.prefetchDataSource = self
        setupFetchedResultsController()

        registerNib()
        // Load users from core data if cached
        if let cachedUsers = fetchedResultsController.fetchedObjects, !cachedUsers.isEmpty {
            // Limit to 20 users
            loadNextBatchFromCoreData()
            self.githubUsers = cachedUsers.prefix(20).map {
                User(id: Int($0.id),
                     login: $0.login ?? "",
                     avatar_url: $0.avatar_url ?? "",
                     html_url: $0.html_url ?? "")
            }
            isInitialLoad = false
            DispatchQueue.main.async {
                self.tblGithubUsers.reloadData()
            }
        } else {
            // Request from API
            loadFirstPage()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start monitoring network
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            if path.status == .unsatisfied {
                // No Internet Connection
                DispatchQueue.main.async {
                  print("No Internet Connection, check your network settings")
                    // Clear local data and update UI
                    self.githubUsers.removeAll()
                    self.tblGithubUsers.reloadData()
                }
            } else {
                // Internet Connection Restored
               
            }
        }
        monitor.start(queue: queue)
    }
    // Register nib file
    func registerNib(){
        tblGithubUsers.register(UINib(nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "userCell")

    }

    // Fetch all github users from API first page
    func loadFirstPage() {
        APIService().fetchGithubUsers { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let users):
                    self.githubUsers = users
                    // Reload table view on the main thread
                    DispatchQueue.main.async {
                        self.tblGithubUsers.reloadData()
                    }
                    self.service.saveUsersToCoreData(self.githubUsers) { saveResult in
                        switch saveResult {
                        case .success():
                            self.isInitialLoad = false
                            print("Frirst page loaded")
                        case .failure(let error):
                            print("Error saving new users: \(error)")
                        }
                    }
                case .failure(let error):
                    print("Error fetching data: \(error)")
                    DispatchQueue.main.async {
                                    let alert = UIAlertController(
                                        title: "Error",
                                        message: "Failed to fetch GitHub users: \(error.asAFError.debugDescription)",
                                        preferredStyle: .alert
                                    )
                                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                                    self.present(alert, animated: true)
                                }
                }
            }
        }
    
    // Table View Delegate & Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return githubUsers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell else {
                return UITableViewCell()
            }
            let user = githubUsers[indexPath.row]
        cell.lblUsername.text = user.login
            cell.imgAvatar.sd_setImage(with: NSURL(string: user.avatar_url) as URL?)
            return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = githubUsers[indexPath.row]
        performSegue(withIdentifier: "goDetailSegues", sender: selectedUser)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goDetailSegues" {
            guard let detailVC = segue.destination as? UserDetailViewController,
                  let user = sender as? User else { return }
            detailVC.user = user
        }
    }
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let urlsToPrefetch = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.row < githubUsers.count else { return nil }
            return URL(string: githubUsers[indexPath.row].avatar_url)
        }
        
        SDWebImagePrefetcher.shared.prefetchURLs(urlsToPrefetch) { finishedCount, skippedCount in
            print("Prefetched \(finishedCount) images, skipped \(skippedCount) images.")
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isInitialLoad {
               return
           }
        if indexPath.row == githubUsers.count - 1{ // Check if this is the last row
                fetchMoreUsers()
        }
    }
    private func loadNextBatchFromCoreData() {
        currentFetchOffset += 20 // Increment offset for the next batch

        // Update fetch request with the new offset
        setupFetchedResultsController(fetchOffset: currentFetchOffset)

        if let nextBatch = fetchedResultsController.fetchedObjects, !nextBatch.isEmpty {
            let newUsers = nextBatch.map {
                User(id: Int($0.id),
                     login: $0.login ?? "",
                     avatar_url: $0.avatar_url ?? "",
                     html_url: $0.html_url ?? "")
            }
            githubUsers.append(contentsOf: newUsers) // Append new users
            DispatchQueue.main.async {
                self.tblGithubUsers.reloadData()
            }
        }
    }
    private func fetchMoreUsers() {
        print("fetchMoreUsers")
        isLoading = true
        service.since += 20
        // Fetch additional users (implement pagination in your API)
        service.fetchUsers { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            // Stop refresh control animation
      
            switch result {
            case .success(let fetchedUsers):
                DispatchQueue.main.async {
                    // Append new users to the existing array
                    self.githubUsers.append(contentsOf: fetchedUsers)
                    self.tblGithubUsers.reloadData()
                }

                // Optionally, save new users to Core Data
                self.service.saveUsersToCoreData(fetchedUsers) { saveResult in
                    switch saveResult {
                    case .success():
                        print("New users saved to Core Data")
                    case .failure(let error):
                        print("Error saving new users: \(error)")
                    }
                }
            case .failure(let error):
                print("Error fetching more users: \(error)")
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to load more users: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    private func fetchUsers() {
            guard !isLoading else { return }
            isLoading = true
            service.fetchUsers { [weak self] result in
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let fetchedUsers):
                    self.service.saveUsersToCoreData(fetchedUsers) { saveResult in
                        switch saveResult {
                        case .success():
                            print("Save success")

                            break
                        case .failure(let error):
                            print("Error saving users: \(error)")
                            // Optionally, show an alert to the user
                        }
                    }
                case .failure(let error):
                    print("Error fetching users: \(error)")
                    // Optionally, show an alert to the user
                }
            }
        }
    private func setupFetchedResultsController(fetchOffset: Int = 0) {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.fetchLimit = 20 // set limit = per page
        fetchRequest.fetchOffset = fetchOffset // Offset for pagination
        let sortDescriptor = NSSortDescriptor(key: "insertDate", ascending: true) // sort criteria
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: CoreDataStack.shared.context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch users: \(error)")
        }
    }
}
