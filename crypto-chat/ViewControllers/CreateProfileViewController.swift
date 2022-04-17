//
//  CreateProfileViewController.swift
//  crypto-chat
//
//  Created by Will Andserson on 2022-04-16.
//

import UIKit

class CreateProfileViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    
    let dataController = DataController.shared
    
    
    // Creates mew profile, programatically performs segue if response from server is good
    @IBAction func createClick(_ sender: Any) {
        // Make sure the name is not blank
        if nameField.text! == "" {
            let alertController = UIAlertController(title: "Missing Data", message: "message: Please enter a name.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        // We may have imported a private key, if not generate one
        var privateKey: String
        if let privateKeyOptional = dataController.getPrivateKey()  {
            privateKey = privateKeyOptional
        } else {
            privateKey = CryptoFacade.createPrivateKey()
            dataController.setPrivateKey(privateKey: privateKey)
        }
        
        // Create the account
        ChatServerClient().createAccount(name: nameField.text!, privateKey:  dataController.getPrivateKey()!) { success, message in
            if(success) {
                // We got a good response, save the profile and segue
                print(message)
                let account: Account = try! JSONDecoder().decode(Account.self, from: message.data(using: .utf8)!)
                self.dataController.setProfile(profile: account)
                DispatchQueue.main.async {
                    // credit: https://fluffy.es/how-to-transition-from-login-screen-to-tab-bar-controller/
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let mainTabBarController = storyboard.instantiateViewController(identifier: "tabBar")
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
                }
            } else {
                // Display error if bad response from server
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error Creating Account", message: "message: \(message)", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}
