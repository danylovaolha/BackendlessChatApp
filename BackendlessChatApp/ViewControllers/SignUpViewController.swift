
import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    private var currentTextField: UITextField?
    
    private let alert = Alert.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        
        self.nameField.delegate = self
        self.nameField.tag = 0
        
        self.emailField.delegate = self
        self.emailField.tag = 1
        
        self.passwordField.delegate = self
        self.passwordField.tag = 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.toolbar.isHidden = true
        registerKeyboardNotifications()
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
    
    func clearFields() {
        self.view.endEditing(true)
        self.nameField.text = ""
        self.emailField.text = ""
        self.passwordField.text = ""
    }
    
    @IBAction func pressedSignUp(_ sender: Any) {
        if let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty {
            let user = BackendlessUser()
            user.email = email as NSString
            user.password = password as NSString
            if let name = nameField.text {
                user.name = name as NSString
            }
            Backendless.sharedInstance()?.userService.register(user, response: { registeredUser in
                self.alert.showRegistrationCompleteAlert(onViewController: self)
            }, error: { fault in
                self.clearFields()
                if let errorMessage = fault?.message {
                    self.alert.showErrorAlert(message: errorMessage, onViewController: self)
                }
            })
        }
        else {
            self.clearFields()
            alert.showErrorAlert(message: "Please check if your email and password are entered correctly", onViewController: self)
        }
    }
}
