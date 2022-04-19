//
//  ChatViewController.swift
//  ande3430_final
//
//  Created by Will Andserson on 2022-04-08.
//

import UIKit

extension UITextView {
    // Extends the UITextView so it stays scrolled to bottom with new lines centered to bottom
    func fixToBottom() {
        // Credit: https://stackoverflow.com/questions/41387549/how-to-align-text-inside-textview-vertically
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale)
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
        // Credit: https://stackoverflow.com/questions/952412/uiscrollview-scroll-to-bottom-programmatically
        let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
        self.setContentOffset(bottomOffset, animated: false)
    }
}

class ChatViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var messageHistory: UITextView!
    @IBOutlet weak var sendText: UITextField!
    
    let dataController = DataController.shared
    
    // This contact will only be set via segue and the prepare() -> setContact() methods
    var contact: Account?
    func setContact(contact: Account) {
        self.contact = contact
        self.navigationItem.title = contact.getName()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
        
        // Subscribe to new messages
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateUI), name: Notification.Name("newMessages"), object: nil)
        self.sendText.delegate = self
    }
    
    // allows textField to send messages with enter
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.sendClick(self)
        return true
    }
    
    // clears message history
    @IBAction func clearClick(_ sender: Any) {
        self.dataController.clearMessages(contact: contact!)
        self.updateUI()
    }
    
    // Encryts and sends message to server
    @IBAction func sendClick(_ sender: Any) {
        // Don't allow sending of empty messages
        if self.sendText.text == "" {
            return
        }
        
        // Sets sender and reciever IDs
        let senderId = self.dataController.getProfile()!.getId()!
        var recieverId = self.dataController.getProfile()!.getId()!
        if let contactId = self.contact?.getId() {
            recieverId = contactId
        }
        
        // Set public and private key
        let privateKey = self.dataController.getPrivateKey()!
        var publicKey = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: privateKey)
        if let contactPublicKey = self.contact?.getPublicKey() {
            publicKey = contactPublicKey
        }
        
        // Ecrypt message
        let encryptedMessage = try! CryptoFacade.sealMessage(privateKey: privateKey, publicKey: publicKey, message: self.sendText.text!)
        self.sendText.text = ""

        // Send message to chat server
        ChatServerClient().sendMessage(message: encryptedMessage, senderId: senderId, recpientId: recieverId, privateKey: privateKey) { success, message in
            if(success) {
                // If successful, add the message to the message array and update UI
                print(message)
                let sentMessage: Message = try! JSONDecoder().decode(Message.self, from: message.data(using: .utf8)!)
                var messages: [Message]
                if let messagesOptional = self.dataController.getMessages() {
                    messages = messagesOptional
                } else {
                    messages = [Message]()
                }
                messages.append(sentMessage)
                self.dataController.setMessages(messages: messages )
                self.updateUI()
            } else {
                print("error sending message")
            }
        }
    }
    
    // Updates UI from noticiations of new messages, as well as manual refreshes
    @objc
    func updateUI() {
        // Set sender and reciever IDs
        let senderId = self.dataController.getProfile()!.getId()!
        var recieverId = self.dataController.getProfile()!.getId()!
        if let contactId = self.contact?.getId() {
            recieverId = contactId
        }
        
        // Set public and private key
        let privateKey = self.dataController.getPrivateKey()!
        var publicKey = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: privateKey)
        if let contactPublicKey = self.contact?.getPublicKey() {
            publicKey = contactPublicKey
        }
        
        // Get list of messages for contact
        if let messages = self.dataController.getMessages(recieverId: recieverId) {
            DispatchQueue.main.async {
                // Rewrite textview with unecrypted messages
                self.messageHistory.text = ""
                for message in messages {
                    let id = message.getSenderId()!
                    // decrypt message
                    let recievedUnencryptedMessage = try! CryptoFacade.unsealMessage(privateKey: privateKey, publicKey: publicKey, message: message.getMessage()!)
                    if id == senderId {
                        // print me: if sent from self
                        self.messageHistory.text = self.messageHistory.text + "\nme: \(recievedUnencryptedMessage)"
                    } else {
                        // print name: if sent by other contact (where name is name of user)
                        if let contactName = self.contact?.getName() {
                            self.messageHistory.text = self.messageHistory.text + "\n\(contactName): \(recievedUnencryptedMessage)"
                        }
                    }
                }
                // fix textview back to bottom
                self.messageHistory.fixToBottom()
            }
        }
    }
}
