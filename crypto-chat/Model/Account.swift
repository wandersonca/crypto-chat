//
//  Account.swift
//  crypto-chat
//
//  Created by Will Andserson on 2022-04-13.
//

import Foundation

// Plain old swift object
class Account: Codable {
    private var name: String?
    private var email: String?
    private var phone: String?
    private var publicKey: String?
    private var id: Int?
    
    func getName() -> String? {
        return self.name;
    }
    
    func getPhone() -> String? {
        return self.phone
    }
    
    func setPhone(phone: String?){
        self.phone = phone
    }
    
    func getEmail() -> String? {
        return self.email
    }
    
    func setEmail(email: String?) {
        self.email = email
    }
    
    func getPublicKey() -> String? {
        return self.publicKey;
    }
    
    func getId() -> Int? {
        return self.id
    }
    
    func setName(name: String?) {
        self.name = name
    }
    
    func setPublicKey(publicKey: String?) {
        self.publicKey = publicKey
    }
    
    func setId(id: Int?) {
        self.id = id
    }
}
