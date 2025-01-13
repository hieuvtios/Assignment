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
import Kingfisher

class ViewController: UIViewController {
    // MARK: - Properties
    private let networkMonitor = NWPathMonitor()
    private let service = GitHubService()
    private let context = CoreDataStack.shared
    
    @IBOutlet weak var tblGithubUsers: UITableView!
    private var users: [User] = []
    private var fetchedResultsController: NSFetchedResultsController<UserEntity>!
    private var isLoading = false
    private var currentPage = 0
    private var isInitialLoad = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFetchedResultsController()
        loadInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startNetworkMonitoring()
    }
}

// MARK: - Setup
private extension ViewController {
    func setupUI() {
        self.tblGithubUsers.register(UINib(nibName: "UserTableViewCell", bundle: nil),
                         forCellReuseIdentifier: "userCell")
        self.tblGithubUsers.delegate = self
        self.tblGithubUsers.dataSource = self
        self.tblGithubUsers.prefetchDataSource = self
    }
    
    func setupFetchedResultsController(fetchOffset: Int = 0) {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 20
        request.fetchOffset = fetchOffset
        request.sortDescriptors = [NSSortDescriptor(key: "insertDate", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        try? fetchedResultsController.performFetch()
    }
    
    func startNetworkMonitoring() {
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if path.status == .unsatisfied {
                    self.handleNoInternet()
                }
            }
        }
        networkMonitor.start(queue: queue)
    }
}

// MARK: - Data Loading
private extension ViewController {
    func loadInitialData() {
        if let cachedUsers = fetchedResultsController.fetchedObjects, !cachedUsers.isEmpty {
            loadFromCache()
        } else {
            loadFirstPage()
        }
    }
    
    func loadFromCache() {
        users = fetchedResultsController.fetchedObjects?
            .prefix(20)
            .map(User.from)
            ?? []
        
        isInitialLoad = false
        self.tblGithubUsers.reloadData()
    }
    
    func loadFirstPage() {
        service.fetchGithubUsers { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let users):
                self.handleFetchSuccess(users)
            case .failure(let error):
                self.handleFetchError(error)
            }
        }
    }
    
    func fetchMoreUsers() {
        guard !isLoading else { return }
        
        isLoading = true
        service.since += 20
        
        service.fetchUsers { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let newUsers):
                self.handlePaginationSuccess(newUsers)
            case .failure(let error):
                self.handleFetchError(error)
            }
        }
    }
}

// MARK: - Helper Methods
private extension ViewController {
    func handleFetchSuccess(_ newUsers: [User]) {
        users = newUsers
        isInitialLoad = false
        
        DispatchQueue.main.async {
            self.tblGithubUsers.reloadData()
        }
        
        service.saveUsersToCoreData(newUsers) { result in
            if case .failure(let error) = result {
                print("Error saving users: \(error)")
            }
        }
    }
    
    func handlePaginationSuccess(_ newUsers: [User]) {
        let startIndex = users.count
        let newIndexPaths = newUsers.indices.map {
            IndexPath(row: startIndex + $0, section: 0)
        }
        
        users.append(contentsOf: newUsers)
        
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tblGithubUsers.insertRows(at: newIndexPaths, with: .none)
            }
        }
        
        service.saveUsersToCoreData(newUsers) { _ in }
    }
    
    func handleFetchError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: "Failed to fetch GitHub users: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func handleNoInternet() {
        users.removeAll()
        self.tblGithubUsers.reloadData()
        print("No Internet Connection, check your network settings")
    }
}

// MARK: - UITableView Delegate & DataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
                as? UserTableViewCell else {
            return UITableViewCell()
        }
        
        let user = users[indexPath.row]
        cell.lblUsername.text = user.login
        if let url = URL(string: user.avatar_url) {
            cell.configure(with: user)
        } else {
            cell.imgAvatar.image = UIImage(named: "placeholder")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                  forRowAt indexPath: IndexPath) {
        if !isInitialLoad && indexPath.row == users.count - 1 {
            fetchMoreUsers()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = users[indexPath.row]
        performSegue(withIdentifier: "goDetailSegues", sender: selectedUser)
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension ViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.row < users.count else { return nil }
            return URL(string: users[indexPath.row].avatar_url)
        }
        
        SDWebImagePrefetcher.shared.prefetchURLs(urls)
    }
}

// MARK: - Navigation
extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goDetailSegues",
           let detailVC = segue.destination as? UserDetailViewController,
           let user = sender as? User {
            detailVC.user = user
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ViewController: NSFetchedResultsControllerDelegate {}

// MARK: - User Mapping
private extension User {
    static func from(_ entity: UserEntity) -> User {
        User(
            id: Int(entity.id),
            login: entity.login ?? "",
            avatar_url: entity.avatar_url ?? "",
            html_url: entity.html_url ?? ""
        )
    }
}

