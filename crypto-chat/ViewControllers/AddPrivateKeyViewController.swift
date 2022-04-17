//
//  AddPrivateKeyViewController.swift
//  crypto-chat
//
//  Created by Will Andserson on 2022-04-16.
//

import UIKit

class AddPrivateKeyViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    let dataController = DataController.shared
    
    // Clears the example private key for an eaiser paste
    @IBAction func clearClick(_ sender: Any) {
        textView.text = ""
    }

    // Only perform segue if the PEM is valid
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        do {
            let privateKey = textView.text!
            // Test loading key to make sure it is valid...
            let _ = try CryptoFacade.getPublicKeyFromPrivateKey(privateKey: privateKey)
            dataController.setPrivateKey(privateKey: privateKey)
            return true
        } catch {
            let alertController = UIAlertController(title: "Error Loading Key", message: "message: \(error)", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return false
        }
    }
}
