
import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageInputField: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var attachmentButton: UIButton!
    
    private(set) var channel: Channel?
    var yourUser: BackendlessUser!
    
    private var messages: [MessageObject]!
    private var messageStore: IDataStore!
    private var messageStoreMap: IDataStore!
    private var longTapped = false
    private var editMode = false
    private var editingMessage: MessageObject?
    
    private let channelName = "MyChannel"
    private let alert = Alert.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        setupMessageField()
        clearMessageField()
        messages = [MessageObject]()
        subscribeForChannel()
        messageStore = Backendless.sharedInstance()?.data.of(MessageObject.self)
        messageStoreMap = Backendless.sharedInstance()?.data.ofTable("MessageObject")
        loadMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.toolbar.isHidden = false
        registerKeyboardNotifications()
        addMessageListeners()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
        removeMessageListeners()
        
        if self.isMovingFromParent {
            performSegue(withIdentifier: "unwindToLoginVC", sender: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func setupMessageField() {
        self.messageInputField.delegate = self
        self.messageInputField.layer.borderColor = UIColor.lightText.cgColor
        self.messageInputField.layer.borderWidth = 1
        self.messageInputField.layer.cornerRadius = 10
        self.messageInputField.translatesAutoresizingMaskIntoConstraints = false
        self.messageInputField.isScrollEnabled = false
        
    }
    
    func clearMessageField() {
        self.view.endEditing(true)
        self.sendButton.isEnabled = false
        self.messageInputField.text = "Message"
        self.messageInputField.textColor = UIColor.lightGray
        self.messageInputField.constraints.forEach({ (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = 35
            }
        })
    }
    
    func subscribeForChannel() {
        channel = Backendless.sharedInstance()?.messaging.subscribe(channelName)
        channel?.addMessageListenerDictionary({ message in
            let messageObject = MessageObject()
            if let message = message as? [String : Any] {
                if let objectId = message["objectId"] as? String {
                    messageObject.objectId = objectId
                }
                if let userId = message["userId"] as? String {
                    messageObject.userId = userId
                }
                if let userName = message["userName"] as? String {
                    messageObject.userName = userName
                }
                if let messageText = message["messageText"] as? String {
                    messageObject.messageText = messageText
                }
                if let created = message["created"] as? Int {
                    messageObject.created = self.intToDate(intVal: created)
                }
                if let updated = message["updated"] as? Int {
                    messageObject.updated = self.intToDate(intVal: updated)
                }
                self.messages.append(messageObject)
                self.tableView.reloadData()
            }
        }, error: { fault in
            if let errorMessage = fault?.message {
                self.alert.showErrorAlert(message: errorMessage, onViewController: self)
            }
        })
    }
    
    func loadMessages() {
        let queryBuilder = DataQueryBuilder()!
        queryBuilder.setSortBy(["created"])
        messageStore.find(queryBuilder, response: { loadedMessages in
            if let loadedMessages = loadedMessages as? [MessageObject] {
                self.messages = loadedMessages
                self.tableView.reloadData()
            }
        }, error: { fault in
            if let errorMessage = fault?.message {
                self.alert.showErrorAlert(message: errorMessage, onViewController: self)
            }
        })
    }
    
    func addMessageListeners() {
        messageStoreMap.rt.addUpdateListener({ updatedMessage in
            if let updatedMessage = updatedMessage as? [String : Any],
                let objectId = updatedMessage["objectId"] as? String,
                let messageText = updatedMessage["messageText"] as? String,
                let message = self.messages.first(where: {$0.objectId == objectId}) {
                message.messageText = messageText
                self.tableView.reloadSections(IndexSet(integer: 0) , with: .fade)
            }
        }, error: { fault in })
        
        messageStoreMap.rt.addDeleteListener({ deletedMessage in
            if let deletedMessage = deletedMessage as? [String : Any],
                let objectId = deletedMessage["objectId"] as? String,
                let index = self.messages.firstIndex(where: {$0.objectId == objectId}) {
                self.messages.remove(at: index)
                self.tableView.reloadSections(IndexSet(integer: 0) , with: .fade)
            }
        }, error: { fault in })
    }
    
    func removeMessageListeners() {
        messageStoreMap.rt.removeAllListeners()
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        let infoValue = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = infoValue.cgRectValue.size
        UIView.animate(withDuration: 0.3, animations: {
            var viewFrame = self.view.frame
            viewFrame.size.height -= keyboardSize.height
            self.view.frame = viewFrame
        })
        scrollToBottom()
    }
    
    func scrollToBottom()  {
        DispatchQueue.main.async {
            let point = CGPoint(x: 0, y: self.tableView.contentSize.height + self.tableView.contentInset.bottom - self.tableView.frame.height)
            if point.y >= 0{
                self.tableView.setContentOffset(point, animated: true)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        UIView.animate(withDuration: 0.3, animations: {
            let screenFrame = UIScreen.main.bounds
            var viewFrame = CGRect(x: 0, y: 0, width: screenFrame.size.width, height: screenFrame.size.height)
            viewFrame.origin.y = 0
            self.view.frame = viewFrame
        })
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollToBottom()
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
            self.sendButton.isEnabled = false
        }
        else {
            self.sendButton.isEnabled = true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        scrollToBottom()
        if textView.text.isEmpty {
            textView.text = "Message"
            textView.textColor = UIColor.lightGray
            self.sendButton.isEnabled = false
        }
        else {
            self.sendButton.isEnabled = true
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            self.sendButton.isEnabled = false
        }
        else {
            self.sendButton.isEnabled = true
        }
        if textView.layoutManager.numberOfLines <= 10 {
            textView.isScrollEnabled = false
            let size = CGSize(width: textView.frame.width, height: .infinity)
            let estimatedSize = textView.sizeThatFits(size)
            textView.constraints.forEach({ (constraint) in
                if constraint.firstAttribute == .height {
                    constraint.constant = estimatedSize.height
                }
            })
            scrollToBottom()
        }
        else {
            textView.isScrollEnabled = true
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageObject = messages[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss / MMM d, yyyy"
        
        if messageObject.userId == yourUser.objectId as String?,
            let messageText = messageObject.messageText,
            let created = messageObject.created {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyTextMessageCell", for: indexPath) as! MyTextMessageCell
            cell.textView.text = messageText
            
            if let updated = messageObject.updated {
                cell.dateLabel.text = "updated " + formatter.string(from: updated)
            }
            else {
                cell.dateLabel.text = formatter.string(from: created)
            }
            
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(sender:)))
            longPress.minimumPressDuration = 0.5
            cell.textView.addGestureRecognizer(longPress)
            
            return cell
        }
        else {
            if  let userName = messageObject.userName,
                let messageText = messageObject.messageText,
                let created = messageObject.created {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextMessageCell", for: indexPath) as! TextMessageCell
                cell.userNameLabel.text = userName
                cell.textView.text = messageText
                
                if let updated = messageObject.updated {
                    cell.dateLabel.text = "updated " + formatter.string(from: updated)
                }
                else {
                    cell.dateLabel.text = formatter.string(from: created)
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func intToDate(intVal: Int) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(intVal / 1000))
    }
    
    func editModeEnabled() {
        self.editMode = true
        self.messageInputField.becomeFirstResponder()
        self.sendButton.setImage(UIImage(named: "done.png"), for: .normal)
        self.attachmentButton.setImage(UIImage(named: "cancel.png"), for: .normal)
        self.attachmentButton.isEnabled = true
    }
    
    func editModeDisabled() {
        self.editMode = false
        self.clearMessageField()
        self.sendButton.setImage(UIImage(named: "send.png"), for: .normal)
        self.attachmentButton.setImage(UIImage(named: "attachment.png"), for: .normal)
        self.attachmentButton.isEnabled = false
    }
    
    @IBAction func longPress(sender: UILongPressGestureRecognizer) {
        if !longTapped {
            longTapped = true
            let touch = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touch),
                let messageObject = self.messages?[indexPath.row],
                messageObject.userId == yourUser.objectId as String? {
                let editAction = UIAlertAction(title: "Edit", style: .default, handler: { action in
                    self.editModeEnabled()
                    self.editingMessage = messageObject
                    self.messageInputField.text = self.editingMessage?.messageText
                    self.longTapped = false
                })
                let deleteAction = UIAlertAction(title: "Delete message", style: .destructive, handler: { acion in
                    self.messageStore.remove(messageObject, response: { removed in
                        self.longTapped = false
                    }, error: { fault in
                    })
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                    self.longTapped = false
                })
                alert.showEditMessageAlert(onViewController: self, editAction: editAction, deleteAction: deleteAction, cancelAction: cancelAction)
            }
        }
    }
    
    @IBAction func pressedSend(_ sender: Any) {
        if !editMode {
            let messageObject = MessageObject()
            if let messageText = messageInputField.text {
                messageObject.messageText = messageText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            if let userName = yourUser.name {
                messageObject.userName = userName as String?
            }
            else if let userEmail = yourUser.email {
                messageObject.userName = userEmail as String?
            }
            messageObject.userId = yourUser.objectId as String?
            
            messageStore.save(messageObject, response: { savedMessageObject in
                Backendless.sharedInstance()?.messaging.publish(self.channelName, message: savedMessageObject, response: { messageStatus in
                    self.clearMessageField()
                }, error: { fault in
                    if let errorMessage = fault?.message {
                        self.alert.showErrorAlert(message: errorMessage, onViewController: self)
                    }
                })
            }, error: { fault in
                if let errorMessage = fault?.message {
                    self.alert.showErrorAlert(message: errorMessage, onViewController: self)
                }
            })
        }
        else {
            if let messageText = messageInputField.text {
                editingMessage?.messageText = messageText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            messageStore.save(editingMessage, response: { updatedMessageObject in
                self.editModeDisabled()
            }, error: { fault in
                if let errorMessage = fault?.message {
                    self.alert.showErrorAlert(message: errorMessage, onViewController: self)
                }
            })
        }
    }
    
    @IBAction func pressedAddAttachment(_ sender: Any) {
        if !editMode {
            
        }
        else {
            self.editModeDisabled()
        }
    }
}


