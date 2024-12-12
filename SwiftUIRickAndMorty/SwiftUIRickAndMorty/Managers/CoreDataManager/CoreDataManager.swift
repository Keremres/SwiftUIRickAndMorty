//
//  CoreDataManager.swift
//  SwiftUIRickAndMorty
//
//  Created by Kerem RESNENLİ on 12.12.2024.
//

import Foundation
import CoreData

protocol CoreDataService {
    var context: NSManagedObjectContext { get }
    func fetch<T: NSManagedObject>(_ entityType: T.Type, searchLocation: String, searchText: String) throws -> [T]?
    func save() throws
    func delete(imageEntity: ImageEntity) throws
}

final class CoreDataManager: CoreDataService {
    private let container: NSPersistentContainer
    let context: NSManagedObjectContext
    
    init(modelName: String = "ImageContainer") {
        self.container = NSPersistentContainer(name: modelName)
        self.container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent store: \(error)")
            }
        }
        self.context = container.viewContext
    }
    
    func fetch<T: NSManagedObject>(_ entityType: T.Type, searchLocation: String, searchText: String) throws -> [T]? {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        let filter = NSPredicate(format: "\(searchLocation) == %@", searchText)
        request.predicate = filter
        do{
            return try context.fetch(request)
        } catch {
            throw BasicErrorAlert.custom(title: CoreDataCustomError.fetchFailed.title,
                                         subtitle: CoreDataCustomError.fetchFailed.subtitle)
        }
    }
    
    func save() throws {
        do {
            try context.save()
        } catch {
            throw BasicErrorAlert.custom(title: CoreDataCustomError.saveFailed.title,
                                         subtitle: CoreDataCustomError.saveFailed.subtitle)
        }
    }
    
    func delete(imageEntity: ImageEntity) throws {
        context.delete(imageEntity)
        do{
            try context.save()
        } catch {
            throw BasicErrorAlert.custom(title: CoreDataCustomError.deleteFailed.title,
                                         subtitle: CoreDataCustomError.deleteFailed.subtitle)
        }
    }
}

enum CoreDataCustomError: ErrorAlert {
    case fetchFailed
    case deleteFailed
    case saveFailed
    
    var title: String {
        switch self {
        case .fetchFailed: return "Fetch Failed"
        case .deleteFailed: return "Delete Failed"
        case .saveFailed: return "Save Failed"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .fetchFailed: return "There was an error fetching the images."
        case .deleteFailed: return "There was an error deleting the image."
        case .saveFailed: return "There was an error saving the image."
        }
    }
}
