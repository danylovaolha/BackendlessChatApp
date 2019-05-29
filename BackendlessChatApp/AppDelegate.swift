
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let APP_ID = "6F4B5218-BECC-9002-FF35-61054C55AD00"
    private let API_KEY = "7E227266-15F2-9A8D-FF05-0DBE57370A00"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Backendless.sharedInstance()?.hostURL = "http://api.backendless.com"
        Backendless.sharedInstance()?.initApp(APP_ID, apiKey: API_KEY)
        return true
    }
}
