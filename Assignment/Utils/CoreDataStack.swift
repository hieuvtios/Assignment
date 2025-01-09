//
//  CoreDataStack.swift
//  Assignment
//
//  Created by Hieu Vu on 1/9/25.
//
import CoreData


class CoreDataStack {
        static let shared = CoreDataStack()

        private init() {
            self.printCoreDataFilePath()
        }

        lazy var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "Assignment") // Ensure this matches your data model name
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Handle error appropriately in production
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            return container
        }()

        var context: NSManagedObjectContext {
            return persistentContainer.viewContext
        }
        func printCoreDataFilePath() {
            if let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url {
                print("Core Data SQLite file is located at: \(storeURL.path)")
            } else {
                print("Core Data SQLite file not found.")
            }
        }
        func saveContext () {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // Handle error appropriately in production
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
}
