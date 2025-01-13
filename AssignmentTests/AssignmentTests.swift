//
//  AssignmentTests.swift
//  AssignmentTests
//
//  Created by Hieu Vu on 1/8/25.
//
import XCTest
import CoreData
@testable import Assignment

class GitHubServiceTests: XCTestCase {
    var sut: GitHubService!
    var mockCoreDataStack: CoreDataStack!
    
    // MARK: - Test Setup
    override func setUp() {
        super.setUp()
        sut = GitHubService.shared
        setupInMemoryManagedObjectContext()
    }
    
    override func tearDown() {
        sut = nil
        mockCoreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func setupInMemoryManagedObjectContext() {
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        
        let container = NSPersistentContainer(name: "Assignment")
        container.persistentStoreDescriptions = [persistentStoreDescription]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        
        mockCoreDataStack = CoreDataStack.shared
        mockCoreDataStack.persistentContainer = container
    }
    
    
    /*
     Purpose: Generates a mock User instance for testing purposes.
     Usage: Used in tests to provide a consistent user object without relying on real data.
    */
    private func createMockUser() -> User {
        return User(
            id: 1,
            login: "testUser",
            avatar_url: "https://example.com/avatar.jpg",
            html_url: "https://github.com/testUser"
        )
    }
    
    
    /*
     Purpose: Generates a mock DetailedUser instance for testing.
     Usage: Provides a more comprehensive user object with additional fields, useful for testing detailed user functionalities.
     */
    private func createMockDetailedUser() -> DetailedUser {
        return DetailedUser(
            login: "testUser",
            id: 1,
            avatar_url: "https://example.com/avatar.jpg",
            html_url: "https://github.com/testUser",
            followers: 100,
            following: 50,
            location: "Test City",
            blog: "https://testblog.com"
        )
    }
    
    // MARK: - Model Tests
    
    /*
     Purpose: Verifies that a User instance can be correctly encoded to JSON and decoded back without loss of data.
     Steps:
     Given: Creates a mock User.
     When: Encodes the User to JSON data and decodes it back to a User instance.
     Then: Asserts that all properties of the original and decoded User are equal.
    */
    func testUserModelCoding() throws {
        // Given
        let user = createMockUser()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(user)
        let decodedUser = try decoder.decode(User.self, from: data)
        
        // Then
        XCTAssertEqual(user.id, decodedUser.id)
        XCTAssertEqual(user.login, decodedUser.login)
        XCTAssertEqual(user.avatar_url, decodedUser.avatar_url)
        XCTAssertEqual(user.html_url, decodedUser.html_url)
    }
    
    
    /*
     Purpose: Similar to testUserModelCoding(), but for the DetailedUser model, ensuring all additional properties are correctly handled.
     Steps:
     Given: Creates a mock DetailedUser.
     When: Encodes and decodes the DetailedUser.
     Then: Asserts equality for all properties, including followers, following, location, and blog.
    */
    func testDetailedUserModelCoding() throws {
        // Given
        let detailedUser = createMockDetailedUser()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(detailedUser)
        let decodedUser = try decoder.decode(DetailedUser.self, from: data)
        
        // Then
        XCTAssertEqual(detailedUser.login, decodedUser.login)
        XCTAssertEqual(detailedUser.id, decodedUser.id)
        XCTAssertEqual(detailedUser.avatar_url, decodedUser.avatar_url)
        XCTAssertEqual(detailedUser.html_url, decodedUser.html_url)
        XCTAssertEqual(detailedUser.followers, decodedUser.followers)
        XCTAssertEqual(detailedUser.following, decodedUser.following)
        XCTAssertEqual(detailedUser.location, decodedUser.location)
        XCTAssertEqual(detailedUser.blog, decodedUser.blog)
    }
    
    // MARK: - GitHub Service Tests
    
    /*
     Purpose: Tests the ability of GitHubService to fetch a list of GitHub users successfully.
     Steps:
     Given: Creates an XCTestExpectation to handle asynchronous behavior.
     When: Calls fetchGithubUsers and handles the result in a closure.
     Then:
     On success:
     Asserts that the returned users array is not empty.
     Checks that the first user has a valid id and login.
     On failure:
     Fails the test with the error message.
     Waits: For the expectation to be fulfilled within 5 seconds, ensuring the asynchronous call completes.
     */
    func testFetchGithubUsers() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch GitHub users")
        
        // When
        sut.fetchGithubUsers { result in
            // Then
            switch result {
            case .success(let users):
                XCTAssertFalse(users.isEmpty, "Users array should not be empty")
                XCTAssertNotNil(users.first?.id)
                XCTAssertNotNil(users.first?.login)
            case .failure(let error):
                XCTFail("Fetch failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /*
     Purpose: Verifies that users fetched from GitHub can be successfully saved to Core Data.
     Steps:
     Given:
     Creates an expectation for the asynchronous save operation.
     Generates a mock user array.
     When: Calls saveUsersToCoreData with the mock users.
     Then:
     On success:
     Fetches users from the in-memory Core Data context.
     Asserts that exactly one user is saved.
     Validates that the saved user's login and id match the mock data.
     On failure:
     Fails the test with the provided error.
     Waits: For the expectation to be fulfilled within 5 seconds.
     */
    func testSaveUsersToCoreData() throws {
        // Given
        let expectation = XCTestExpectation(description: "Save users to Core Data")
        let mockUsers = [createMockUser()]
        
        // When
        sut.saveUsersToCoreData(mockUsers) { result in
            // Then
            switch result {
            case .success:
                let context = self.mockCoreDataStack.context
                let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                do {
                    let savedUsers = try context.fetch(fetchRequest)
                    XCTAssertEqual(savedUsers.count, 1)
                    XCTAssertEqual(savedUsers.first?.login, "testUser")
                    XCTAssertEqual(Int(savedUsers.first?.id ?? 0), 1)
                } catch {
                    XCTFail("Failed to fetch saved users: \(error)")
                }
            case .failure(let error):
                XCTFail("Save failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /*
     Purpose: Tests the pagination logic of the GitHubService, ensuring that subsequent fetches retrieve the correct set of users.
     Steps:
     Given: Creates an expectation for the asynchronous fetch operation.
     When: Calls fetchUsers and handles the result.
     Then:
     On success:
     Asserts that the number of fetched users matches the expected perPage value.
     Checks that the since property (used for pagination) is updated to the id of the last fetched user.
     On failure:
     Fails the test with the provided error.
     Waits: For the expectation to be fulfilled within 5 seconds.
     */
    func testPagination() {
        // Given
        let expectation = XCTestExpectation(description: "Test pagination")
        
        // When
        sut.fetchUsers { [weak self] result in
            guard let self = self else { return }
            
            // Then
            switch result {
            case .success(let users):
                XCTAssertEqual(users.count, self.sut.perPage)
                XCTAssertEqual(self.sut.since, users.last?.id)
            case .failure(let error):
                XCTFail("Pagination failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    /*
     Purpose: Ensures that attempting to fetch and save user details with invalid URLs results in a failure.
     Steps:
     Given:
     Creates an expectation for the asynchronous operation.
     Constructs a User instance with empty strings for URLs, simulating invalid URLs.
     When: Calls fetchAndSaveUserDetails with the invalid user.
     Then:
     On success:
     Fails the test because it was expected to fail due to invalid URLs.
     On failure:
     Passes the test as this is the expected behavior.
     Waits: For the expectation to be fulfilled within 5 seconds.
     */
    func testInvalidURLError() {
        // Given
        let expectation = XCTestExpectation(description: "Test invalid URL")
        let invalidUser = User(id: 1, login: "", avatar_url: "", html_url: "")
        
        // When
        sut.fetchAndSaveUserDetails(for: invalidUser) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Should fail with invalid URL")
            case .failure:
                // Success - we expected this to fail
                break
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    
    /*
     Purpose: Tests the service's ability to handle duplicate users, ensuring that duplicate entries are not created in Core Data.
     Steps:
     Given:
     Creates an expectation for the asynchronous save operation.
     Generates an array with two identical mock users.
     When: Calls saveUsersToCoreData with the duplicate users.
     Then:
     On success:
     Fetches users from the in-memory Core Data context.
     Asserts that only one user is saved, indicating that duplicates were not created.
     On failure:
     Fails the test with the provided error.
     Waits: For the expectation to be fulfilled within 5 seconds.
     */
    func testDuplicateUserHandling() throws {
        // Given
        let expectation = XCTestExpectation(description: "Test duplicate user handling")
        let mockUsers = [createMockUser(), createMockUser()] // Same user twice
        
        // When
        sut.saveUsersToCoreData(mockUsers) { result in
            // Then
            switch result {
            case .success:
                let context = self.mockCoreDataStack.context
                let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                do {
                    let savedUsers = try context.fetch(fetchRequest)
                    XCTAssertEqual(savedUsers.count, 1, "Should not create duplicate users")
                } catch {
                    XCTFail("Failed to fetch saved users: \(error)")
                }
            case .failure(let error):
                XCTFail("Save failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

