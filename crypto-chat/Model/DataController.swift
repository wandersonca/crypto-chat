//
//  DataController.swift
//  crypto-chat
//
//  Created by Will Andserson on 2022-04-13.
//
import Foundation
import CryptoKit


class DataController {
    // Singleton reference
    static let shared = DataController()
    private init() {}
    
    // Data to manage
    private var profile : Account?
    private var privateKey : String?
    private var contacts : [Account]?
    private var messages: [Message]?
    
    // Timer to fetch new messages
    private var timer: Timer?
    
    func getProfile() -> Account? {
        return self.profile
    }
    
    func setProfile(profile: Account?) {
        self.profile = profile
        self.saveData()
    }
    
    func getPrivateKey() -> String? {
        return self.privateKey
    }
    
    func setPrivateKey(privateKey: String?) {
        self.privateKey = privateKey
        self.saveData()
    }
    
    func getContacts() -> [Account]? {
        return self.contacts
    }
    
    func setContacts(contacts: [Account]?) {
        self.contacts = contacts
        self.saveData()
    }
    
    func removeContact(contact: Account) {
        self.clearMessages(contact: contact)
        self.contacts?.removeAll(where: {$0.getId() == contact.getId()})
    }
    
    // Will filter messages if recieverId is provided
    func getMessages(recieverId: Int? = nil) -> [Message]? {
        guard let messages = messages else {
            return nil
        }
        if let receiverIdOptional = recieverId {
            return messages.filter{ message in
                return message.getSenderId()! == receiverIdOptional || message.getRecipientId()! == receiverIdOptional
            }
        } else {
            return messages
        }
    }
    
    
    // Runs on a timer (started after loadData)
    @objc
    private func fetchMessages() {
        guard let id = self.getProfile()?.getId(), let privateKey = self.getPrivateKey() else {
            return
        }
        ChatServerClient().getMessage(id: id, privateKey: privateKey) { success, message in
            if(success) {
                
                let newMessages: [Message] = try! JSONDecoder().decode([Message].self, from: message.data(using: .utf8)!)
                if !newMessages.isEmpty {
                    print(message)
                    if let oldMessages = self.getMessages() {
                        self.setMessages(messages: oldMessages + newMessages)
                    } else {
                        self.setMessages(messages: newMessages)
                    }
                    NotificationCenter.default.post(name: Notification.Name("newMessages"), object: nil)
                } else {
                    print("No messages..")
                }
            } else {
                print("error getting message message")
            }
        }
    }
    
    
    func setMessages(messages: [Message]?) {
        self.messages = messages
        self.saveData()
    }
    
    
    func clearMessages(contact: Account) {
        self.messages?.removeAll(where: {$0.getSenderId() == contact.getId() || $0.getRecipientId() == contact.getId()})
    }
    
    
    
    // Persists data to storage
    func saveData(){
        print("Going to save.")
        let jsonEncoder = JSONEncoder()
        if let profile = self.profile {
            self.writeFile(jsonData: try! jsonEncoder.encode(profile), filename: "profile")
        }
        if let privateKey = self.privateKey {
            self.writeFile(jsonData: try! jsonEncoder.encode(privateKey), filename: "privateKey")
        }
        if let contacts = self.contacts {
            self.writeFile(jsonData: try! jsonEncoder.encode(contacts), filename: "contacts")
        }
        if let messages = self.messages {
            self.writeFile(jsonData: try! jsonEncoder.encode(messages), filename: "messages")
        }
        
    }
    
    
    // Loads data from storage
    func loadData(){
        print("Loading Data")
        let jsonDecoder = JSONDecoder()
        if let profileData = self.readFile(filename: "profile") {
            self.profile = try? jsonDecoder.decode(Account.self, from: profileData)
        }
        if let privateKey = self.readFile(filename: "privateKey") {
            self.privateKey = try? jsonDecoder.decode(String.self, from: privateKey)
        }
        if let contacts = self.readFile(filename: "contacts") {
            self.contacts = try? jsonDecoder.decode([Account].self, from: contacts)
        }
        if let messages = self.readFile(filename: "messages") {
            self.messages = try? jsonDecoder.decode([Message].self, from: messages)
        }
        if let timer = self.timer {
            timer.invalidate()
        }
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fetchMessages), userInfo: nil, repeats: true)
    }
    
    
    // Helper to write files
    private func writeFile(jsonData: Data, filename: String) {
        let jsonString = String(data: jsonData, encoding: .utf8)
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(filename)
            do {
                try jsonString!.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {}
            print("Write to \(filename) complete")
        }
    }
    
    
    // Helper to read files
    private func readFile(filename: String) -> Data? {
        var jsonData: Data?
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(filename)
            do {
                jsonData = try Data(contentsOf: fileURL)
                print("Read \(filename) complete")
            } catch {}
        }
        return jsonData
    }
    
    
    // Removes files when we want to clear application state
    private func removeFile(filename: String) {
        let fileManager = FileManager()
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(filename)
            
            // Check if file exists
            if fileManager.fileExists(atPath: fileURL.path) {
                // Delete file
                try? fileManager.removeItem(atPath: fileURL.path)
            } else {
                print("File \(filename) does not exist")
            }
        }
    }
    
    
    // Clears application state when we delete the primary profile
    func clear() {
        self.profile = nil
        self.removeFile(filename: "profile")
        self.messages = nil
        self.removeFile(filename: "messages")
        self.privateKey = nil
        self.removeFile(filename: "privateKey")
        self.contacts = nil
        self.removeFile(filename: "contacts")
        self.saveData()
    }
}
