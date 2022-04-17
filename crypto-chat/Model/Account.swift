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
    private var publicKey: String?
    private var id: Int?
    
    func getName() -> String? {
        return self.name;
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
