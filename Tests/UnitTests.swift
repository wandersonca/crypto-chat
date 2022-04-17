//
//  crypto_chatTests.swift
//  crypto-chatTests
//
//  Created by Will Andserson on 2022-04-13.
//

import XCTest
import CryptoKit
@testable import crypto_chat

class UnitTests: XCTestCase {
    let serverClient: ChatServerClient =  ChatServerClient()
    let privateKeyForID26: String = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgTqN5c1Hkx2xhhXOa
    EoY+MCr/SYhSX7iAzPm66j3KBcGhRANCAATWbZkSM5I+1DB0iFUX/KhU4FtfvBTL
    lRkcepmWshkYXC1MGVvgH3i6zCYt0c0EcR0PUq2as8vcDW4C/IHsms4b
    -----END PRIVATE KEY-----
    """

    let privateKeyForID27: String = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgyVxOKD2SFcD0pRc6
    u64BYuy3OXcsN/EGpFk7Q32OIimhRANCAARU54XcgLPg9YcduxH7Rw62x6wJztDF
    /8z40RT9xWXo0mhi7SCyP09dV2KgumgljfyNuQtWVZa2w53fzWj+3UPv
    -----END PRIVATE KEY-----
    """

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: CryptoFacade Tests
    func testPrivateKeyCreation() throws {
        let privateKey: String = CryptoFacade.createPrivateKey()
        XCTAssertTrue(privateKey.range(of: "-----BEGIN PRIVATE KEY-----") != nil)
    }
    
    func testPublicKeyCreation() throws {
        let privateKey: String = CryptoFacade.createPrivateKey()
        let publicKey: String = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: privateKey)
        XCTAssertTrue(publicKey.range(of: "-----BEGIN PUBLIC KEY-----") != nil)
    }
    
    func testSignatureCreation() throws {
        let privateKey: String = CryptoFacade.createPrivateKey()
        let data: Data = "test data".data(using: .utf8)!
        let signature: String = try! CryptoFacade.createSignature(privateKey: privateKey, data: data)
        let publicKeyObject = try! P256.Signing.PrivateKey(pemRepresentation: privateKey).publicKey
        
        let signatureObj =  try! P256.Signing.ECDSASignature(derRepresentation: Data(base64Encoded: signature)!)
        XCTAssertTrue(publicKeyObject.isValidSignature(signatureObj, for: data))
    }
    
    func testSealingMessages() throws {
        let publicKeyForID26 = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: self.privateKeyForID26)
        let publicKeyForID27 = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: self.privateKeyForID27)
        
        let unencryptedMessage = "Hi friend"
        let encryptedMessage = try! CryptoFacade.sealMessage(privateKey: self.privateKeyForID26, publicKey: publicKeyForID27, message: unencryptedMessage)
        let unsealedMessage = try! CryptoFacade.unsealMessage(privateKey: self.privateKeyForID27, publicKey: publicKeyForID26, message: encryptedMessage)
        XCTAssertTrue(unencryptedMessage == unsealedMessage)
    }
    
    func testUnsealWithSameKey() throws {
        let publicKeyForID27 = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: self.privateKeyForID27)
        
        let unencryptedMessage = "Hi friend"
        // use same key to decrypt
        let encryptedMessage = try! CryptoFacade.sealMessage(privateKey: self.privateKeyForID26, publicKey: publicKeyForID27, message: unencryptedMessage)
        let unsealedMessage = try! CryptoFacade.unsealMessage(privateKey: self.privateKeyForID26, publicKey: publicKeyForID27, message: encryptedMessage)
        XCTAssertTrue(unencryptedMessage == unsealedMessage)
    }
    

    // MARK: Test ChatServerClient
    func testAccountCreation() throws {
        let expectation = XCTestExpectation(description: "Create Account")
        let privateKey: String = CryptoFacade.createPrivateKey()
        ChatServerClient().createAccount(name: "Will", privateKey: privateKey) { success, message in
            if(success) {
                print(message)
                let account: Account = try! JSONDecoder().decode(Account.self, from: message.data(using: .utf8)!)
                if let id = account.getId() {
                    print(id)
                }
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testMessaging() throws {
        let sendExepectation = XCTestExpectation(description: "Send Message")
        let recieveExepectation = XCTestExpectation(description: "Send Message")
        let publicKeyForID26 = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: self.privateKeyForID26)
        let publicKeyForID27 = try! CryptoFacade.getPublicKeyFromPrivateKey(privateKey: self.privateKeyForID27)
        
        let unencryptedMessage = "Hi friend"
        let encryptedMessage = try! CryptoFacade.sealMessage(privateKey: self.privateKeyForID26, publicKey: publicKeyForID27, message: unencryptedMessage)
        
        ChatServerClient().sendMessage(message: encryptedMessage, senderId: 26, recpientId: 27, privateKey: self.privateKeyForID26) { success, message in
            if(success) {
                sendExepectation.fulfill()
            }
        }
        wait(for: [sendExepectation], timeout: 3.0)
        
        ChatServerClient().getMessage(id: 27, privateKey: self.privateKeyForID27) { success, message in
            if(success) {
                print(message)
                let messages: [Message] = try! JSONDecoder().decode([Message].self, from: message.data(using: .utf8)!)
                if let encryptedMessage = messages.last?.getMessage() {
                    print("ecrypted Message:" + encryptedMessage)
                    let recievedUnencryptedMessage = try! CryptoFacade.unsealMessage(privateKey: self.privateKeyForID27, publicKey: publicKeyForID26, message: encryptedMessage)
                    print("unecrypted Message:" + recievedUnencryptedMessage)
                    XCTAssertTrue(recievedUnencryptedMessage == unencryptedMessage)
                    recieveExepectation.fulfill()
                }
            }
        }
        wait(for: [recieveExepectation], timeout: 3.0)
    }
    

    // MARK: dataController test, one big test as it is a singleton
    func testDataController() throws {
        let dataController = DataController.shared
        dataController.clear()
        let contact1 = Account()
        contact1.setId(id: 1)
        let contact2 = Account()
        contact2.setId(id: 2)
        let contact3 = Account()
        contact3.setId(id: 3)
        let message1 = Message()
        message1.setSenderId(senderId: 1)
        message1.setRecipientId(recipientId: 2)
        let message2 = Message()
        message2.setSenderId(senderId: 2)
        message2.setRecipientId(recipientId: 1)
        let message3 = Message()
        message3.setSenderId(senderId: 3)
        message3.setRecipientId(recipientId: 1)
        dataController.setContacts(contacts: [contact1, contact2, contact3])
        dataController.setMessages(messages: [message1, message2, message3])
        // Test deleting an account and it's messages
        dataController.removeContact(contact: contact2)
        XCTAssertTrue(dataController.getContacts()!.count == 2)
        // Make sure a cascading delete happens
        XCTAssertTrue(dataController.getMessages()!.count == 1)
        
    }
}
