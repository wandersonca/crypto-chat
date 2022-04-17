//
//  ConversationTableViewController.swift
//  ande3430_final
//
//  Created by Will Andserson on 2022-04-08.
//

import UIKit

class ConversationCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numLabel: UILabel!
    @IBOutlet weak var lastLabel: UILabel!
}


class ConversationTableViewController: UITableViewController {
    let dataController = DataController.shared
    
    // Reloads the data when we come back from another screen (helpful for likes/dislikes)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.rowHeight = 70
        self.tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: Notification.Name("newMessages"), object: nil)
    }
    
    // Update the table view when noticiations come in
    @objc
    func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // Send contact to conversation vc before segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "ShowConversation" {
            guard let conversationViewController = segue.destination as? ConversationViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedCell = sender as? ConversationCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let contact = self.dataController.getContacts()![indexPath.row]
            conversationViewController.setContact(contact: contact)
        }
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
        let cellIdentifier = "ConversationCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ConversationCell  else {
            fatalError("The dequeued cell is not an instance of TableViewCell.")
        }
        
        guard let contacts = self.dataController.getContacts() else {
            fatalError("Contacts missing.")
        }
        
        let contact = contacts[indexPath.row]
        cell.nameLabel.text = contact.getName()! + "(\(String(contact.getId()!)))"
        if let messages = dataController.getMessages(recieverId: contact.getId()!) {
            cell.numLabel.text = "\(messages.count) message(s)"
            if messages.count > 0 {
                // Last message should be most recent
                let lastMessage = messages.last!
                
                // Decrypt message to display in table
                let privateKey = dataController.getPrivateKey()!
                let publicKey = contact.getPublicKey()!
                let message = try! CryptoFacade.unsealMessage(privateKey: privateKey, publicKey: publicKey, message: lastMessage.getMessage()!)
                
                // Print most recent message
                if lastMessage.getSenderId()! == contact.getId()! {
                    cell.lastLabel.text = "> \(contact.getName()!): \(message)"
                } else {
                    cell.lastLabel.text = "> me: \(message)"
                }
                
            } else {
                cell.numLabel.text = "0 messages"
                cell.lastLabel.text = ""
            }
        } else {
            cell.numLabel.text = "0 messages"
            cell.lastLabel.text = ""
        }
        return cell
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
}
