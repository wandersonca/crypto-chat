//
//  CryptoFacade.swift
//  crypto-chat
//
//  Created by Will Andserson on 2022-04-13.
//
import Foundation
import CryptoKit

class CryptoFacade {
    // Create the required salt to use for all AES ecryption
    static let protocolSalt: Data = "crypto-chat".data(using: .utf8)!
    
    // Returns a brand new private key in PEM format
    static func createPrivateKey() -> String {
        let privateKey = P256.Signing.PrivateKey()
        return privateKey.pemRepresentation
    }
    
    // Generates a public key in PEM format for a given private key, throws error if private key is invalid
    static func getPublicKeyFromPrivateKey(privateKey: String) throws -> String  {
        let publicKey = try P256.KeyAgreement.PrivateKey(pemRepresentation: privateKey).publicKey
        return publicKey.pemRepresentation
    }
    
    // Creates a ECDSA signature in DER format for a given input, throws error if invalid key or data
    static func createSignature(privateKey: String, data: Data) throws -> String  {
        // Convert PEM reperentation to Signing Objects
        let privateKeyObj = try P256.Signing.PrivateKey(pemRepresentation: privateKey)
        
        // Sign Data
        let signatureForData = try privateKeyObj.signature(for: data)
        
        // Generate and return der representation
        return  signatureForData.derRepresentation.base64EncodedString()
    }
    
    // Seals a message in a with AES symmetric key encryption using a shared key generated with a Diffie Hellman key exchange
    static func sealMessage(privateKey: String, publicKey: String, message:String) throws -> String {
        // Convert PEM reperentation to KeyAgreement Objects
        let senderPrivateKey = try P256.KeyAgreement.PrivateKey(pemRepresentation: privateKey)
        let recieverPublicKey = try P256.KeyAgreement.PublicKey(pemRepresentation: publicKey)
        
        // Generate the shared key using the a Diffie Hellman key exchange
        let sharedSecret = try senderPrivateKey.sharedSecretFromKeyAgreement(with: recieverPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: self.protocolSalt, sharedInfo: Data(), outputByteCount: 32)
        
        // Seal the data
        let dataToSeal = message.data(using: .utf8)!
        let encryptedData = try AES.GCM.seal(dataToSeal, using: symmetricKey)
        
        // Convert to String and return
        let stringRepresentation = encryptedData.combined!.base64EncodedString()
        return stringRepresentation
    }
    
    // Unseals a message in a with AES symmetric key encryption using a shared key generated with a Diffie Hellman key exchange
    static func unsealMessage(privateKey: String, publicKey: String, message:String) throws -> String {
        // Convert PEM reperentation to KeyAgreement Objects
        let recieverPrivateKey = try P256.KeyAgreement.PrivateKey(pemRepresentation: privateKey)
        let senderPublicKey = try P256.KeyAgreement.PublicKey(pemRepresentation: publicKey)
        
        // Generate the shared key
        let sharedSecret = try recieverPrivateKey.sharedSecretFromKeyAgreement(with: senderPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: self.protocolSalt, sharedInfo: Data(), outputByteCount: 32)
        //print(sharedSecret)
        
        // Unseal the data
        let data = Data(base64Encoded: message)
        let sealedBox = try AES.GCM.SealedBox(combined: data!)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        // Convert to String and return
        let stringRepresentation = String(data: decryptedData, encoding: .utf8)
        return stringRepresentation!
    }
}
