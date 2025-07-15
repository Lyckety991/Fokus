//
//  FocusStore.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//

import Foundation
import CoreData

class FocusStore: ObservableObject {
    private let context = DataController.shared.context
    
    @Published var focusItems: [FocusItemModel] = []
    @Published var userProgress: UserProgressModel?
    
    init() {
        loadAllData()
    }
    
    func loadAllData() {
        loadFocusItems()
        loadUserProgress()
    }
    
    // MARK: - CRUD: Focus hinzufügen
    func addFocus(_ focus: FocusItemModel) {
        let entity = FocusItem(context: context)
        entity.id = focus.id
        entity.title = focus.title
        entity.desc = focus.description
        entity.weakness = focus.weakness
        
        // CompletionDates als transformierbares Attribut speichern
        entity.completionDates = NSArray(array: focus.completionDates)
        
        for todo in focus.todos {
            let todoEntity = FocusToDo(context: context)
            todoEntity.id = todo.id
            todoEntity.title = todo.title
            todoEntity.isCompleted = todo.isCompleted
            entity.addToTodos(todoEntity)
        }
        
        saveContext()
        focusItems.append(focus)
    }
    
    // MARK: - Focus aktualisieren
    func updateFocus(_ focus: FocusItemModel) {
        let request: NSFetchRequest<FocusItem> = FocusItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", focus.id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                entity.title = focus.title
                entity.desc = focus.description
                entity.weakness = focus.weakness
                
                // CompletionDates aktualisieren
                entity.completionDates = NSArray(array: focus.completionDates)
                
                if let existingTodos = entity.todos as? Set<FocusToDo> {
                    for todo in existingTodos {
                        context.delete(todo)
                    }
                }
                
                for todo in focus.todos {
                    let todoEntity = FocusToDo(context: context)
                    todoEntity.id = todo.id
                    todoEntity.title = todo.title
                    todoEntity.isCompleted = todo.isCompleted
                    entity.addToTodos(todoEntity)
                }
                
                saveContext()
                
                if let index = focusItems.firstIndex(where: { $0.id == focus.id }) {
                    focusItems[index] = focus
                }
            }
        } catch {
            print("❌ Update fehlgeschlagen: \(error)")
        }
    }
    
    // MARK: - Focus als abgeschlossen markieren
    func completeFocus(_ focusId: UUID) {
        guard let focusIndex = focusItems.firstIndex(where: { $0.id == focusId }) else { return }
        
        let currentDate = Date()
        var updatedFocus = focusItems[focusIndex]
        
        // Füge das aktuelle Datum hinzu, wenn noch nicht vorhanden
        if !updatedFocus.completionDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: currentDate) }) {
            updatedFocus.completionDates.append(currentDate)
        }
        
        // CoreData aktualisieren
        let request: NSFetchRequest<FocusItem> = FocusItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", focusId as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                // Konvertiere NSArray zu [Date] und füge neues Datum hinzu
                var dates = (entity.completionDates as? [Date]) ?? []
                
                if !dates.contains(where: { Calendar.current.isDate($0, inSameDayAs: currentDate) }) {
                    dates.append(currentDate)
                    entity.completionDates = NSArray(array: dates)
                }
                
                saveContext()
            }
        } catch {
            print("❌ Abschluss fehlgeschlagen: \(error)")
        }
        
        // Lokale Daten aktualisieren
        focusItems[focusIndex] = updatedFocus
        addXP(amount: 25)
        resetTodos(for: focusId)
    }
    
    // MARK: - Focus-Daten laden
    private func loadFocusItems() {
        let request: NSFetchRequest<FocusItem> = FocusItem.fetchRequest()
        
        do {
            let entities = try context.fetch(request)
            focusItems = entities.map { entity in
                let todos = (entity.todos as? Set<FocusToDo>)?.map {
                    FocusTodoModel(
                        id: $0.id ?? UUID(),
                        title: $0.title ?? "",
                        isCompleted: $0.isCompleted
                    )
                } ?? []
                
                // Konvertiere NSArray zu [Date] für completionDates
                let completionDates = (entity.completionDates as? [Date]) ?? []
                
                return FocusItemModel(
                    id: entity.id ?? UUID(),
                    title: entity.title ?? "",
                    description: entity.desc ?? "",
                    weakness: entity.weakness ?? "",
                    todos: todos,
                    completionDates: completionDates
                )
            }
        } catch {
            print("❌ Fehler beim Laden der FocusItems: \(error)")
        }
    }
    
    // MARK: - Fortschritt laden
    private func loadUserProgress() {
        let request: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
        
        do {
            if let entity = try context.fetch(request).first {
                userProgress = UserProgressModel(totalXP: Int(entity.totalXP))
            } else {
                createInitialUserProgress()
            }
        } catch {
            print("❌ Fehler beim Laden des Fortschritts: \(error)")
        }
    }
    
    // MARK: - Initialer Fortschritt
    private func createInitialUserProgress() {
        let entity = UserProgress(context: context)
        entity.totalXP = 0
        saveContext()
        userProgress = UserProgressModel(totalXP: 0)
    }
    
    // MARK: - XP hinzufügen
    private func addXP(amount: Int) {
        let request: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
        
        do {
            if let entity = try context.fetch(request).first {
                entity.totalXP += Int64(amount)
                saveContext()
                userProgress = UserProgressModel(totalXP: Int(entity.totalXP))
            } else {
                createInitialUserProgress()
                addXP(amount: amount)
            }
        } catch {
            print("❌ Fehler beim Hinzufügen von XP: \(error)")
        }
    }
  
    func deleteFocus(_ focus: FocusItemModel) {
        let request: NSFetchRequest<FocusItem> = FocusItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", focus.id as CVarArg)

        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                saveContext()
                focusItems.removeAll { $0.id == focus.id }
            }
        } catch {
            print("❌ Fehler beim Löschen des Fokus: \(error)")
        }
    }
    
    // MARK: - Todos zurücksetzen
    private func resetTodos(for focusId: UUID) {
        let request: NSFetchRequest<FocusItem> = FocusItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", focusId as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first,
               let todos = entity.todos as? Set<FocusToDo> {
                for todo in todos {
                    todo.isCompleted = false
                }
                saveContext()
            }
        } catch {
            print("❌ Todo-Reset fehlgeschlagen: \(error)")
        }
        
        if let index = focusItems.firstIndex(where: { $0.id == focusId }) {
            for i in 0..<focusItems[index].todos.count {
                focusItems[index].todos[i].isCompleted = false
            }
        }
    }
    
    // MARK: - Speichern
    private func saveContext() {
        DataController.shared.saveContext()
    }
}
