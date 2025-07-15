//
//  CoreDataHelper.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//

import Foundation
import CoreData


// MARK: - FocusItemModel ↔︎ FocusItem (CoreData)
extension FocusItemModel {
    static func create(from entity: FocusItem) -> FocusItemModel {
        let todos = (entity.todos as? Set<FocusToDo>)?.compactMap {
            FocusTodoModel.create(from: $0)
        } ?? []
        
        return FocusItemModel(
            title: entity.title ?? "",
            description: entity.desc ?? "",
            weakness: entity.weakness ?? "",
            todos: todos,
            completionDates: entity.lastCompletionDate?.isToday ?? false ? [Date()] : []
        )
    }

    func updateEntity(_ entity: FocusItem, context: NSManagedObjectContext) {
        entity.id = self.id
        entity.title = self.title
        entity.desc = self.description
        entity.weakness = self.weakness
        entity.lastCompletionDate = self.lastCompletionDate

        // Alle alten Todos löschen, bevor neue gesetzt werden
        if let oldTodos = entity.todos as? Set<FocusToDo> {
            for old in oldTodos {
                context.delete(old)
            }
        }

        let newTodoEntities: [FocusToDo] = todos.map { todo in
            let todoEntity = FocusToDo(context: context)
            todoEntity.id = todo.id
            todoEntity.title = todo.title
            todoEntity.isCompleted = todo.isCompleted
            return todoEntity
        }

        entity.todos = NSSet(array: newTodoEntities)
    }
}



// MARK: - FocusTodoModel ↔︎ FocusTodo (CoreData)
extension FocusTodoModel {
    static func create(from entity: FocusToDo) -> FocusTodoModel {
        return FocusTodoModel(
            title: entity.title ?? "",
            isCompleted: entity.isCompleted
        )
    }
}


// MARK: - UserProgressModel ↔︎ UserProgress (CoreData)
extension UserProgressModel {
    static func create(from entity: UserProgress) -> UserProgressModel {
        return UserProgressModel(
            totalXP: Int(entity.totalXP)
        )
    }

    func updateEntity(_ entity: UserProgress) {
        entity.totalXP = Int64(self.totalXP)
    }
}

