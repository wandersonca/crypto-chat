//
//  Message.swift
//  crypto-chat
//
//  Created by Will Andserson on 2022-04-13.
//

import Foundation

// Plain old swift object
class Message: Codable {
    private var message: String?
    private var recipientId: Int?
    private var senderId: Int?
    private var messageId: Int?
    
    func getMessage() -> String? {
        return self.message;
    }
    
    func getRecipientId() -> Int? {
        return self.recipientId
    }
    
    func getSenderId() -> Int? {
        return self.senderId
    }
    
    func getMessageId() -> Int? {
        return self.messageId
    }
    
    func setSenderId(senderId: Int?) {
        self.senderId = senderId
    }
    
    func setRecipientId(recipientId: Int?) {
        self.recipientId = recipientId
    }
    
    func setMessageId(messageId: Int?) {
        self.messageId = messageId
    }
    
    func setMessage(message: String?) {
        self.message = message
    }
}
