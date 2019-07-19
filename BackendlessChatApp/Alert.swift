
import UIKit

class Alert: NSObject {
    
    static let shared = Alert()
    
    private let darkBlueColor: UIColor
    
    private override init() {
        darkBlueColor = UIColor(rgb: 005493)
    }
    
    func showErrorAlert(message: String, onViewController: UIViewController) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
    
    func showRestorePasswordAlert(onViewController: UIViewController) {
        let alert = UIAlertController(title: "Restore password", message: "Enter your email and we'll send the instructions on how to reset the password", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "email"
        })
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { action in
            if let email = alert.textFields?.first?.text, !email.isEmpty {
                Backendless.sharedInstance()?.userService.restorePassword(email, response: {
                    let alert = UIAlertController(title: "Password reset email sent", message: "An email has been sent to the provided email address. Follow the email instructions to reset your password", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    alert.view.tintColor = self.darkBlueColor
                    onViewController.present(alert, animated: true)
                }, error: { fault in
                    if let errorMesssage = fault?.message {
                        self.showErrorAlert(message: errorMesssage, onViewController: onViewController)
                    }
                })
            }
            else {
                self.showErrorAlert(message: "Please provide the correct email address to restore password", onViewController: onViewController)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
    
    func showRegistrationCompleteAlert(onViewController: UIViewController) {
        let alert = UIAlertController(title: "Registration complete", message: "Please login to continue", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            onViewController.performSegue(withIdentifier: "unwindToLoginVC", sender: nil)
        }))
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
    
    func showEditMessageAlert(onViewController: UIViewController, editAction: UIAlertAction, deleteAction: UIAlertAction, cancelAction: UIAlertAction) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
    
    func showSendImageAlert(onViewController: UIViewController, cameraAction: UIAlertAction, galleryAction: UIAlertAction, cancelAction: UIAlertAction) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
    
    func showSaveImageAlert(onViewController: UIViewController, image: UIImage, saveAction: UIAlertAction) {
        let alert = UIAlertController(title: "Save image to Photos", message: "Would you like to save this image in the photo library?", preferredStyle: .alert)
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
    
    func showSavedImageAlert(onViewController: UIViewController) {
        let alert = UIAlertController(title: "Saved", message: "Image has been saved in photo library", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
    
    func showDeleteImageAlert(onViewController: UIViewController, deleteAction: UIAlertAction) {
        let alert = UIAlertController(title: "Delete image", message: "Would you like to delete this image from chat?", preferredStyle: .alert)
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.view.tintColor = darkBlueColor
        onViewController.view.endEditing(true)
        onViewController.present(alert, animated: true)
    }
}
