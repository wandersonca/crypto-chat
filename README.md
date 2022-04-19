# Crypto-Chat
This iPhone app is a proof-of-concept chat application that is centred around secure transmission of messages. The messages between two individuals are secured with AES symmetric key encryption derived from a diffie hellman key exchange of private and public elliptic curve keys. You can see the chat server implementation in this [repo](https://github.com/wandersonca/chat-server).

# Project Layout
* The **ChatServerClient** folder contains two important classes that are reused throughout the application.
    * A static **CryptoFacade** class which helps with generating keys, signing message payloads, and both encrypting and decrypting messages. 
    * A **ChatServerClient** that handles all HTTP requests for creating accounts, looking up accounts, sending messages and receiving messages. The client uses closures to return a success flag and payloads for each request.
* The **Model** folder contains the two main data objects and a controller. 
    * The **DataController** is a singleton that manages all persistent data, and stores it to the filesystem when state is changed. It contains all messages, profile data, private key and contact information. It is also within this class where a timer is started to periodically poll the server for new messages. 
    * The **Account** class is a simple Swift class that stores all account information for a user. It is also used to store the current users profile. 
    * A **Message** class is another simple Swift class that stores the contents of a message, including who sent it, etc. 
* The ViewController folder contains all views and related controller code. Most of these classes leverage the ChatServerClient, the CryptoFacade class as well as data from the model folder and its DataController class. 
    * **AddPrivateKeyViewController** - This ViewController validates a user entered private key and segues onto the next screen as part of account creation.
    * **CreateProfileViewController** - This ViewController lets the user enter a name for the account creation. This may be extended to include other contact information like and email or phone number. 
    * **ContactViewController** - This ViewController is a table view that lists all contacts, let’s you add new contacts with a modal alert popup, delete contacts (does a cascading delete of all associated messages), and allows the user to click the contact for more information. 
    * **ConversationsViewController** - This ViewController is a table view that lists all contacts, the number of messages and the latest message. When a cell is clicked, you are taken to the individual chat ViewController. 
    * **ChatViewController** - This ViewController is the main chat view. It contains a full screen textview that gets programmatically updated and pinned to the bottom when text messages are long enough to scroll offscreen. There is a clear button to locally delete all messages within the active chat.  
    * **AccountViewController** - THis ViewController displays both the current profile for the active user, but also doubles to show information about other contacts. It has a delete button which, if the active user, will delete all application state and kick the user back to the account creation screen. If a contact, it will delete the contact along with all messages for that user. 

# Testing
This project has unit tests! You can find them in the `Tests` folder. 

This project was also tested on the following devices:
* iPhone 13 Pro Max
* iPod Touch (7th Generation)
* iPad Pro (9.7-inch)

# Limitations
There was a lot I could not do, due to the time frame, here are some things that jump out:
* The [server implentation](https://github.com/wandersonca/chat-server) is quite basic and could be optimised with caching and connection pooling.
 For the iPhone app:
* Cosmetically it could use a bit more UI styling, most importantly the current method of using  a large textview for the chat doesn’t allow for distinctive styling of each individual message. 
* From a performance standpoint, messages should be locally stored unencrypted once decrypted so they are not repeatedly decrypted for each view load. 
* From a flexibility standpoint, it’d be good to support more than one key type other than elliptic curve P256 keys.  
* From an ease of use and convenience standpoint, notifications would be helpful, and contact management features like blocking users, sending contact requests, group chats, etc would be nice to have. 
