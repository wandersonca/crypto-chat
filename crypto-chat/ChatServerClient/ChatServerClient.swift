//
//  ChatServerClient.swift
//  crypto-chat
//
//  Created by Will Andserson on 2022-04-10.
//

import Foundation

class ChatServerClient {
    // Production instance, for local testing switch to http://localhost:3000
    let baseURL: String = "https://murmuring-journey-13653.herokuapp.com"
    
    
    // Creates an Account, asynchronous result and data sent back with a closure
    func createAccount(name: String, phone: String = "", email: String = "", privateKey: String, completionBlock: @escaping (Bool, String) -> Void) {
        // Create an account object to send to server
        let newAccount = Account()
        do {
            let publicKey = try CryptoFacade.getPublicKeyFromPrivateKey(privateKey: privateKey)
            newAccount.setPublicKey(publicKey: publicKey)
        } catch {
            completionBlock(false, "Failed to create public key from private key: \(error)")
        }
        newAccount.setName(name: name)
        newAccount.setPhone(phone: phone)
        newAccount.setEmail(email: email)
    
        // Encode object in JSON
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        var jsonData: Data?
        do {
            jsonData = try jsonEncoder.encode(newAccount)
        } catch {
            completionBlock(false, "JSON encoding failed: \(error)")
        }
        
        // Create ECDSA signature
        var derSignature: String?
        do {
            derSignature = try CryptoFacade.createSignature(privateKey: privateKey, data: jsonData!)
        } catch {
            completionBlock(false, "ECDSA signing failed: \(error)")
        }
        
        // POST account to API, forward on closure
        self.requestHandler(path: "/account", jsonData: jsonData, method: "POST", derSignature: derSignature!, completionBlock: completionBlock)
    }
    
    
    // Looks up an account on the server for a given ID, asynchronous result and data sent back with a closure
    func getAccount(id: Int, completionBlock: @escaping (Bool, String) -> Void) {
        // GET account from API, forward on closure
        self.requestHandler(path: "/account/\(id)", completionBlock: completionBlock)
    }
    
    
    // Sends a message to the server, uses private key to sign the message, asynchronous result and data sent back with a closure
    func sendMessage(message: String, senderId: Int, recpientId: Int, privateKey: String, completionBlock: @escaping (Bool, String) -> Void) {
        let newMessage = Message()
        newMessage.setMessage(message: message)
        newMessage.setSenderId(senderId: senderId)
        newMessage.setRecipientId(recipientId: recpientId)
        
        // Encode object in JSON
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        var jsonData: Data?
        do {
            jsonData = try jsonEncoder.encode(newMessage)
        } catch {
            completionBlock(false, "JSON encoding failed: \(error)")
        }
        
        // Create ECDSA signature
        var derSignature: String?
        do {
            derSignature = try CryptoFacade.createSignature(privateKey: privateKey, data: jsonData!)
        } catch {
            completionBlock(false, "ECDSA signing failed: \(error)")
        }
        
        // POST message to API, forward on closure
        self.requestHandler(path: "/message", jsonData: jsonData, method: "POST", derSignature: derSignature, completionBlock: completionBlock)
    }
    
    
    // Gets messages for user, asynchronous result and data sent back with a closure
    func getMessage(id: Int, privateKey: String, completionBlock: @escaping (Bool, String) -> Void) {
        // Create ECDSA signature with the ID
        var derSignature: String?
        do {
            derSignature = try CryptoFacade.createSignature(privateKey: privateKey, data: "\(id)".data(using: .utf8)!)
        } catch {
            completionBlock(false, "ECDSA signing failed: \(error)")
        }
        
        // POST to API, forward on closure
        self.requestHandler(path: "/message/\(id)", derSignature: derSignature, completionBlock: completionBlock)
    }
    
    
    // Helper method to get data from server, asynchronous result and data sent back with a closure
    private func requestHandler(path: String, jsonData: Data? = nil, method: String = "GET", derSignature: String? = nil, completionBlock: @escaping (Bool, String) -> Void) {
        // create the complete URL with baseURL and the path
        let url = URL(string: "\(self.baseURL)\(path)")!
        
        // create the session object
        let session = URLSession.shared
        
        // now create the URLRequest object using the url object
        var request = URLRequest(url: url)

        // pass along request JSON
        if let jsonDataOptional = jsonData {
            request.httpBody = jsonDataOptional
        }
        
        //set http method as POST
        request.httpMethod = method
        
        // add headers for the request, including the signature
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let derSignatureOptional = derSignature {
            request.addValue(derSignatureOptional, forHTTPHeaderField: "Authentication-Signature")
        }
        
        // create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completionBlock(false, error.localizedDescription)
                return
            }
            
            // ensure there is valid response code returned from this HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                if let dataOptional = data {
                    let stringValue = String(decoding: dataOptional, as: UTF8.self)
                    completionBlock(false, stringValue)
                } else {
                    completionBlock(false, "Invalid Response received from the server")
                }
                return
            }
            
            // ensure there is data returned
            guard let responseData = data else {
                completionBlock(false, "nil Data received from the server")
                return
            }
            
            let responseString = String(decoding: responseData, as: UTF8.self)
            completionBlock(true, responseString)
        }
        task.resume()
    }
}
