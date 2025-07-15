//
//  DataController.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//

import CoreData

class DataController: ObservableObject {
    static let shared = DataController()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Focus")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData Fehler: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CoreData Speicherfehler: \(error)")
            }
        }
    }
}

