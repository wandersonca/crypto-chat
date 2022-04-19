//
//  ProfileViewController.swift
//  ande3430_final
//
//  Created by Will Andserson on 2022-04-08.
//

import UIKit
import CryptoKit

class AccountViewController: UIViewController {
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var publicKey: UITextView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    
    private let dataController = DataController.shared
    
    // This account will only be set via segue and the prepare() -> setAccount() methods
    // isOwner tracks if VC is deplaying the current user and not a contact
    private var account: Account?
    private var isOwner = false
    func setAccount(account: Account) {
        self.account = account
        self.isOwner = false
    }
    
    // If owner, we delete all application state, if contact, delete the user and all messages
    @IBAction func deleteClick(_ sender: Any) {
        if isOwner {
            // Clear application state
            self.dataController.clear()
            // segue back to login page after clearing the data
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = storyboard.instantiateViewController(identifier: "signup")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginViewController)
        } else {
            // Remove the contact (and all messages)
            self.dataController.removeContact(contact: self.account!)
            // Segue off current view
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mainTabBarController = storyboard.instantiateViewController(identifier: "tabBar")
           (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // detect if we're displaying self or a contact
        if self.account == nil {
            self.account = self.dataController.getProfile()
            self.isOwner = true
        }
        self.updateUI()
    }
    
    // Display profile information for both contacts and self
    func updateUI() {
        if isOwner {
            // Change title if displaying the profile for current user
            self.navigationItem.title = "Account Profile"
            // Remove the message button
            self.messageButton.isHidden = true
        }
        // Update UI elements
        if let account = self.account {
            if let id = account.getId() {
                let idString = String(id)
                self.idLabel.text = "ID: \(idString)"
            }
            if let name = account.getName() {
                self.nameLabel.text = "Name: \(name)"
                if !self.isOwner {
                    self.navigationItem.title = name
                }
            }
            if var phone = account.getPhone() {
                if phone == "" {
                    phone = "N/A"
                }
                self.phoneLabel.text = "Phone: \(phone)"
            }
            if var email = account.getEmail() {
                if email == "" {
                    email = "N/A"
                }
                self.emailLabel.text = "Email: \(email)"
            }
            if let publicKey = account.getPublicKey() {
                self.publicKey.text = publicKey
            }
        }
    }
    
    // Segue to conversation view, set the contact we are starting conversation with
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let conversationViewController = segue.destination as? ChatViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        conversationViewController.setContact(contact: self.account!)
    }
}
