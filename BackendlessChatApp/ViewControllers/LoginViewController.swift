
import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    
    let chatSegue = "segueToChatVC"
    
    private var currentTextField: UITextField?
    private var yourUser: BackendlessUser?
    
    private let alert = Alert.shared    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        
        self.emailField.delegate = self
        self.emailField.tag = 0
        
        self.passwordField.delegate = self
        self.passwordField.tag = 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.toolbar.isHidden = true
        registerKeyboardNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentUser = Backendless.sharedInstance()?.userService.currentUser, Backendless.sharedInstance()?.userService.isValidUserToken() ?? false {
            self.yourUser = currentUser
            performSegue(withIdentifier: chatSegue, sender: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
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
        guard let keyboardFrame = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        self.scrollView.contentInset.bottom = view.convert(keyboardFrame.cgRectValue, from: nil).size.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        self.scrollView.contentInset.bottom = 0
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.currentTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.currentTextField?.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == chatSegue,
            let chatVC = segue.destination as? ChatViewController {
            chatVC.yourUser = self.yourUser
        }
    }
    
    func clearFields() {
        self.view.endEditing(true)
        self.emailField.text = ""
        self.passwordField.text = ""
    }
    
    @IBAction func pressedStartChatting(_ sender: Any) {
        if self.rememberMeSwitch.isOn {
            Backendless.sharedInstance()?.userService.setStayLoggedIn(true)
        }
        else {
            Backendless.sharedInstance()?.userService.setStayLoggedIn(false)
        }
        
        if let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty {
            Backendless.sharedInstance()?.userService.login(email, password: password, response: { loggedInUser in
                self.yourUser = loggedInUser
                self.clearFields()
                self.performSegue(withIdentifier: self.chatSegue, sender: nil)
            }, error: { fault in
                self.clearFields()
                if let errorMessage = fault?.message {
                    self.alert.showErrorAlert(message: errorMessage, onViewController: self)
                }
            })
        }
        else {
            clearFields()
            alert.showErrorAlert(message: "Please check if your email and password are entered correctly", onViewController: self)
        }
    }
    
    @IBAction func pressedForgotPassword(_ sender: Any) {
        alert.showRestorePasswordAlert(onViewController: self)
    }
    
    @IBAction func unwindToLoginVC(segue: UIStoryboardSegue) {
        if let chatVC = segue.source as? ChatViewController,
            let channel = chatVC.channel {
            channel.leave()
            Backendless.sharedInstance()?.userService.setStayLoggedIn(false)
            Backendless.sharedInstance()?.userService.logout({ }, error: { fault in
                if let errorMessage = fault?.message {
                    self.alert.showErrorAlert(message: errorMessage, onViewController: self)
                }
            })
        }
    }
}
