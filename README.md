❖ User Story:
As an administrator, it is possible to browse all users who are the members of
GitHub site then we can see more detailed information about them.

❖ Acceptance Criteria:
o The administrator can look through fetched users’ information.
o The administrator can scroll down to see more users’ information with 20
items per fetch.
o Users’ information must be shown immediately when the administrator
launches the application for the second time.
o Clicking on an item will navigate to the page of user details.

Structure of Project
```bash
Assignment/
├── Cells
│   ├── UserTableViewCell
│   └── UserTableViewCell.xib
├── AppDelegate
├── SceneDelegate
├── Assets.xcassets
│   ├── Icons
│   └── AppIcon.appiconset
├── Extentions
│   ├── UIImage+
├── Models
│   ├── GitHubService: Handling interactions with the GitHub API and Core Data
│   └── JsonObjects: Structure of objects using in API
├── Views
│   └── Preview Assets.xcassets
├── Utils
│   ├── Constants: Static constants 
│   └── CoreDataStack: Core Data initial setup method
├── Assignment.xcdatamodeld
│   └── Assignment.xcdatamodel : Core Data File
AssignmentTests/
├── AssignmentTests : Unit test cases of application
Pods/
├── Podfile 
```
Demo video: https://youtube.com/shorts/MX9TBJVQm7I?feature=share
