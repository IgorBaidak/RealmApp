//
//  TasksListsTVC.swift
//  RealmApp
//
//  Created by Igor Baidak on 13.09.22.
//

import UIKit
import RealmSwift

var notificationToken: NotificationToken?


class TasksListsTVC: UITableViewController {
    
    // Results - отображает данные в реальном времени
    var tasksLists: Results<TasksList>!

    override func viewDidLoad() {
        super.viewDidLoad()
        

//        /// Clean Realm DB
//        StorageManager.deleteAll()

        // выборка из DB + сортировка
        tasksLists = StorageManager.getAllTasksLists().sorted(byKeyPath: "name")
        
        // добавляем кнопки "+" и "edit" в bar button
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBarButtonSystemItemSelector))
        self.navigationItem.setRightBarButtonItems([add, editButtonItem], animated: true)
    }
    
    // меняем сортировку в segmented controll
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            tasksLists = tasksLists.sorted(byKeyPath: "name")
        } else {
            tasksLists = tasksLists.sorted(byKeyPath: "date")
        }
        tableView.reloadData()
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasksLists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let tasksList = tasksLists[indexPath.row]
        cell.textLabel?.text = tasksList.name
        cell.detailTextLabel?.text = tasksList.tasks.count.description
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    // добавляем кнопки редактирования при свайпе ячейки
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let currentList = tasksLists[indexPath.row]

        let deleteContextItem = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.deleteList(currentList)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }

        let editeContextItem = UIContextualAction(style: .destructive, title: "Edite") { _, _, _ in
            self.alertForAddAndUpdatesListTasks(currentList) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }

        let doneContextItem = UIContextualAction(style: .destructive, title: "Done") { _, _, _ in
            StorageManager.makeAllDone(currentList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        editeContextItem.backgroundColor = .orange
        doneContextItem.backgroundColor = .green

        let swipeAtions = UISwipeActionsConfiguration(actions: [deleteContextItem, editeContextItem, doneContextItem])

        return swipeAtions
    }

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */
    
    // MARK: - Table view delegate

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? TasksTVC,
           let index = tableView.indexPathForSelectedRow {
           let tasksList = tasksLists[index.row]
            destinationVC.currentTaskList = tasksList
        }
    }
    
    @objc private func addBarButtonSystemItemSelector() {
        alertForAddAndUpdatesListTasks { [weak self] in
            self?.navigationItem.title = "alertForAddAndUpdatesListTasks"
            print("ListTasks")
        }
    }

    // Делаем alertForAddAndUpdatesListTasks универсальной функцией
    private func alertForAddAndUpdatesListTasks(_ tasksList: TasksList? = nil,
                                                complition: @escaping () -> Void)
    {
        let title = tasksList == nil ? "New List" : "Edit List"
        let message = "Please insert list name"
        let doneButtonName = tasksList == nil ? "Save" : "Update"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        var alertTextField: UITextField!
        let saveAction = UIAlertAction(title: doneButtonName, style: .default) { _ in
            guard let newListName = alertTextField.text, !newListName.isEmpty else {
                return
            }

            if let tasksList = tasksList {
                StorageManager.editList(tasksList, newListName: newListName, complition: complition)
            } else {
                let tasksList = TasksList()
                tasksList.name = newListName
                StorageManager.saveTasksList(tasksList: tasksList)
                self.tableView.reloadData()
                //                self.tableView.insertRows(at: [IndexPath(row: self.tasksLists.count - 1, section: 0)], with: .automatic)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        alert.addTextField { textField in
            alertTextField = textField
            if let listName = tasksList {
                alertTextField.text = listName.name
            }
            alertTextField.placeholder = "List Name"
        }
        present(alert, animated: true)
    }
    
    private func addTasksListsObserver() {
            // Realm notification
        
            notificationToken = tasksLists.observe { change in
                switch change {
                case .initial:
                    print("initial element")
                case .update(_, let deletions, let insertions, let modifications):
                        
                    print("deletions: \(deletions)")
                    print("insertions: \(insertions)")
                    print("modifications: \(modifications)")

                    if !modifications.isEmpty {
                        var indexPathArray = [IndexPath]()
                        for row in modifications {
                            indexPathArray.append(IndexPath(row: row, section: 0))
                        }
                        self.tableView.reloadRows(at: indexPathArray, with: .automatic)
                    }
                    if !deletions.isEmpty {
                        var indexPathArray = [IndexPath]()
                        for row in deletions {
                            indexPathArray.append(IndexPath(row: row, section: 0))
                        }
                        self.tableView.deleteRows(at: indexPathArray, with: .automatic)
                    }
                    if !insertions.isEmpty {
                        var indexPathArray = [IndexPath]()
                        for row in insertions {
                            indexPathArray.append(IndexPath(row: row, section: 0))
                        }
                        self.tableView.insertRows(at: indexPathArray, with: .automatic)
                    }
                case .error(let error):
                    print("error: \(error)")
                }
            }
        }

//    @objc func addBarButtonSystemItemSelector() {
//        // Names
//        let title = "New List"
//        let massege = "Please insert list name"
//        let doneBtnName = "Save"
//
//        // AlertController
//        let alert = UIAlertController(title: title, message: massege, preferredStyle: .alert)
//
//        // TextField
//        var alerTextField: UITextField!
//        alert.addTextField { textField in
//            alerTextField = textField
//            alerTextField.placeholder = "List Name"
//        }
//
//        // Actions
//        let saveAction = UIAlertAction(title: doneBtnName, style: .default) { _ in
//            guard let newListName = alerTextField.text, !newListName.isEmpty else {
//                return
//            }
//            let tasksList = TasksList()
//            tasksList.name = newListName
//            StorageManager.saveTasksList(tasksList: tasksList)
////            self.tableView.insertRows(at: [IndexPath(row: self.tasksLists.count - 1, section: 0)], with: .automatic)
//            self.tableView.reloadData()
//        }
//        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
//        alert.addAction(saveAction)
//        alert.addAction(cancelAction)
//
//        present(alert, animated: true)
//    }
}
