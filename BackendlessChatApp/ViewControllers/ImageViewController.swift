
import UIKit

class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var messageId = ""
    var messageUserId = ""
    var shortImagePath: String = ""
    private var fullImagePath = ""    
    private let alert = Alert.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Backendless.sharedInstance()?.userService.currentUser.objectId as String? != messageUserId {
            deleteButton.isEnabled = false
        }
        if let appId = Backendless.sharedInstance()?.appID,
            let apiKey = Backendless.sharedInstance()?.apiKey {
            fullImagePath = "https://backendlessappcontent.com/\(appId)/\(apiKey)/files/\(shortImagePath)"
            downloadImage(fullImagePath: fullImagePath)
        }
    }
    
    private func downloadImage(fullImagePath: String) {
        if let image = getImageFromUserDefaults(key: shortImagePath) {
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
        else {
            loadingIndicator.startAnimating()
            URLSession.shared.dataTask(with: NSURL(string: fullImagePath)! as URL, completionHandler: { (data, response, error) -> Void in
                if error != nil {
                    Alert.shared.showErrorAlert(message: error?.localizedDescription ?? "", onViewController: self)
                }
                else if let imageData = data,
                    let image = UIImage(data: imageData) {
                    self.saveImageToUserDefaults(image: image, key: self.shortImagePath)
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        self.loadingIndicator.stopAnimating()
                    }
                }
            }).resume()
        }
    }
    
    private func saveImageToUserDefaults(image: UIImage, key: String) {
        let userDefaults = UserDefaults.standard
        if let imageData = image.pngData() {
            userDefaults.setValue(imageData, forKey: key)
            userDefaults.synchronize()
        }
    }
    
    private func getImageFromUserDefaults(key: String) -> UIImage? {
        let userDefaults = UserDefaults.standard
        if let imageData = userDefaults.value(forKey: key) as? Data {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    private func deleteImageFromUserDefaults(key: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            alert.showErrorAlert(message: error.localizedDescription, onViewController: self)
        } else {
            alert.showSavedImageAlert(onViewController: self)
        }
    }
    
    @IBAction func pressedSave(_ sender: Any) {
        if let image = imageView.image {
            let saveAction = UIAlertAction(title: "Save to Photos", style: .default, handler: { action in
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            })
            alert.showSaveImageAlert(onViewController: self, image: image, saveAction: saveAction)
        }
    }
    
    @IBAction func pressedDelete(_ sender: Any) {
        let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: { action in
            Backendless.sharedInstance()?.file.remove(self.shortImagePath, response: { removed in
                Backendless.sharedInstance()?.data.of(MessageObject.self)?.remove(byId: self.messageId, response: { removed in
                    self.deleteImageFromUserDefaults(key: self.shortImagePath)
                    self.performSegue(withIdentifier: "unwindToChatVC", sender: nil)
                }, error: { fault in
                    self.alert.showErrorAlert(message: fault?.message ?? "", onViewController: self)
                })
            }, error: { fault in
                self.alert.showErrorAlert(message: fault?.message ?? "", onViewController: self)
            })
        })
        alert.showDeleteImageAlert(onViewController: self, deleteAction: deleteAction)
    }
}
