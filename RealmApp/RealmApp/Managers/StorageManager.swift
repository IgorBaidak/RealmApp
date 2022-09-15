//
//  StorageManager.swift
//  RealmApp
//
//  Created by Igor Baidak on 13.09.22.
//

import Foundation
import RealmSwift

let realm = try! Realm()

class StorageManager {
    
    static func deleteAll() {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("deleteAll error: \(error)")
        }
    }
    
    static func getAllTasksLists() -> Results<TasksList> {
        realm.objects(TasksList.self)//.sorted(byKeyPath: "name")
    }
    
    static func saveTasksList(tasksList: TasksList) {
        do {
            try realm.write {
                realm.add(tasksList)
            }
        } catch {
            print("saveTasksList error: \(error)")
        }
    }

    static func deleteList(_ tasksList: TasksList) {
        do {
            try realm.write {
                let tasks = tasksList.tasks
                // последовательно удаляем tasks и tasksList
                realm.delete(tasks)
                realm.delete(tasksList)
            }
        } catch {
            print("deleteList error: \(error)")
        }
    }

    static func editList(_ tasksList: TasksList,
                         newListName: String,
                         complition: @escaping () -> Void) {
        do {
            try realm.write {
                tasksList.name = newListName
                complition()
            }
        } catch {
            print("editList error")
        }
    }

    static func makeAllDone(_ tasksList: TasksList) {
        do {
            try realm.write {
                tasksList.tasks.setValue(true, forKey: "isComplete")
            }
        } catch {
            print("makeAllDone error: \(error)")
        }
        try! realm.write {
            tasksList.tasks.setValue(true, forKey: "isComplete")
        }
    }
//
    // MARK: - Tasks Methods

    static func saveTask(_ tasksList: TasksList, task: Task) {
        try! realm.write {
            tasksList.tasks.append(task)
        }
    }

    static func editTask(_ task: Task, newNameTask: String, newNote: String) {
        try! realm.write {
            task.name = newNameTask
            task.note = newNote
        }
    }
    
    static func saveTasks(tasks: Task) {
        do {
            try realm.write {
                realm.add(tasks)
            }
        } catch {
            print("saveTasks error: \(error)")
        }
    }

    static func deleteTask(_ task: Task) {
        try! realm.write {
            realm.delete(task)
        }
    }

    static func makeDone(_ task: Task) {
        try! realm.write {
            task.isComplete.toggle()
        }
    }
}

