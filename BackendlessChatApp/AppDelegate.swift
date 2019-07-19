
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let APP_ID = "YOUR_APP_ID"
    private let API_KEY = "YOUR_API_KEY"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Backendless.sharedInstance()?.hostURL = "http://api.backendless.com"
        Backendless.sharedInstance()?.initApp(APP_ID, apiKey: API_KEY)
        return true
    }
}
