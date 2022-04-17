//
//  ContactsViewController.swift
//  ande3430_final
//
//  Created by Will Andserson on 2022-04-08.
//

import UIKit

class ContactCell: UITableViewCell {
    @IBOutlet weak var idLabel: UILabel!
}

class ContactsViewController: UITableViewController {
    let dataController = DataController.shared
    
    // Reloads the data when we come back from another screen (helpful for likes/dislikes)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    // Segue handler, set the contact in the profile view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "ShowContact" {
            guard let profileViewController = segue.destination as? ProfileViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedCell = sender as? ContactCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            // send the correct contact based on it is sorted id
            let contact = self.dataController.getContacts()!.sorted(by: { $0.getId()! < $1.getId()! })[indexPath.row]
            profileViewController.setAccount(account: contact)
        }
    }
    
    // Adds a new contact via an alert, retrieves contact from server after some validations
    @IBAction func addClick(_ sender: Any) {
        // Make a confirmation alert dialog.
        let alert = UIAlertController(
            title: "Enter ID",
            message: "Enter the numeric ID of the contact:",
            preferredStyle: .alert
        )
        
        // Add a text field to get user name.
        alert.addTextField { textField in _ = textField.text}
        
        // Add cancel action.
        alert.addAction(UIAlertAction(title: "Cancel",style: .destructive, handler: { _ in} ))
        
        // Action to fetch contact from server
        let addAction  = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            
            // Performs three validations
            if let name = alert.textFields?.first?.text {
                // 1. Must be numeric
                guard let id = Int(name) else {
                    let alertController = UIAlertController(title: "Error Adding Contact", message: "Message: Must use numeric ID", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                    return
                }
                // 2. Cannot add self
                if id == self?.dataController.getProfile()!.getId()! {
                    let alertController = UIAlertController(title: "Error Adding Contact", message: "Message: Cannot add self", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                    return
                }
                // 3. Cannot add same contact twice
                if let contacts = self?.dataController.getContacts() {
                    if contacts.firstIndex(where: {$0.getId()! == id}) != nil {
                        let alertController = UIAlertController(title: "Error Adding Contact", message: "Message: Cannot add same account twice", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
                        self?.present(alertController, animated: true, completion: nil)
                        return
                    }
                }
                
                // Get contact from server
                ChatServerClient().getAccount(id: id) { success, message in
                    if(success) {
                        // Add contact and update table
                        print(message)
                        let account: Account = try! JSONDecoder().decode(Account.self, from: message.data(using: .utf8)!)
                        if var contacts = self?.dataController.getContacts() {
                            // Append the contact
                            contacts.append(account)
                            self?.dataController.setContacts(contacts: contacts)
                        } else {
                            // No contacts exist, create a fresh array
                            var contacts = [Account]()
                            contacts.append(account)
                            self?.dataController.setContacts(contacts: contacts)
                        }
                        
                        // Reload the table
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    } else {
                        // Display error from server (i.e. contact not fount)
                        let alertController = UIAlertController(title: "Error Adding User", message: "message: \(message)", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
                        DispatchQueue.main.async {
                            self?.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        alert.addAction(addAction)
        // Show pop-up. Add a completion when pop-up is destroyed.
        self.present(alert, animated: true, completion: nil );
    }
    
    
    
    // MARK: UITableViewController Delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // UITableViewController delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int = 0
        if let contacts = self.dataController.getContacts() {
            count = contacts.count
        }
        return count
    }
    
    // UITableViewController delegates
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ContactCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ContactCell  else {
            fatalError("The dequeued cell is not an instance of TableViewCell.")
        }
        
        guard let contacts = self.dataController.getContacts() else {
            fatalError("Contacts missing.")
        }
        
        // order contacts by ID
        let contact = contacts.sorted(by: { $0.getId()! < $1.getId()! })[indexPath.row]
        cell.idLabel.text = contact.getName()! + "(\(String(contact.getId()!)))"
        
        return cell
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard var contacts = self.dataController.getContacts() else {
                fatalError("Contacts missing.")
            }
            // delete the correct contact based on it is sorted id
            let contact = contacts.sorted(by: { $0.getId()! < $1.getId()! })[indexPath.row]
            contacts.removeAll(where: { $0.getId()! == contact.getId()! })
            self.dataController.setContacts(contacts: contacts)
            self.tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
}
