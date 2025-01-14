Structure of Project

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
│   ├── UIImage+: UIImage's Extension
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


Template-Base-iOS/
├── Ads+Purchase
│   ├── Ads
│   └── Purchase
├── AppDelegate+SceneDelegate
├── Assets.xcassets
│   ├── Colors: All color App using
│   ├── ImagesAndIcon: All Icon and Images App using
│   └── AppIcon.appiconset
├── Data
│   ├── ConfigHelper: Debug and Release config
│   ├── KeychainHelper: iPhone Device Storage Variable
│   └── UserDefaultsHelper: App Local Storage Variables
├── DependencyInject
├── Firebase
│   └── RemoteConfigHelper: Firebase Remote Config Variables
├── Helper
│   └── RateUsHelper: App Rate Us 
├── Preview Content
│   └── Preview Assets.xcassets
├── Scene
│   ├── SwiftUI: All Template SwiftUI Scene View
│   └── UIKit: All Template UIKit Scene
├── Services
│   ├── NetworkService: Network Service
│   └── PermissionService: All Request and State Permission 
├── Template_Base_iOS.xcdatamodeld
│   └── Template_Base_iOS.xcdatamodel
├── Tracking
│   ├── AdjustTracking: Adjust SDK tracking revenue functions
│   ├── FacebookTracking: Facebook SDK tracking functions
│   ├── FirebaseTracking: Firebase SDK tracking functions
│   └── ScreenTracking: SwiftUI tracking ScreenView
└── Utils
    └── Logger
