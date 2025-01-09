//
//  ViewController.swift
//  Assignment
//
//  Created by Hieu Vu on 1/8/25.
//

import UIKit
import SDWebImage

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    var githubUsers: [GithubUser] = []
    
    @IBOutlet weak var tblGithubUsers: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib()
        loadGithubUsers()
        // Do any additional setup after loading the view.
    }
    
    // Register nib file
    func registerNib(){
        tblGithubUsers.register(UINib(nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "userCell")

    }
    // Fetch all github users
    func loadGithubUsers() {
        APIService().fetchGithubUsers { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let users):
                    self.githubUsers = users
                    
                    // Reload table view on the main thread
                    DispatchQueue.main.async {
                        self.tblGithubUsers.reloadData()
                    }
                    
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        }
    
    // Table View Delegate & Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return githubUsers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell else {
                return UITableViewCell()
            }
            let user = githubUsers[indexPath.row]
            cell.lblUsername.text = user.login
            cell.imgAvatar.sd_setImage(with: NSURL(string: user.avatarURL) as URL?)
            return cell
    }
    

}

