import UIKit
import Parse

extension UIViewController {
    func showAlertWithError(error: NSError) {
        let isReachable = Reachability.reachabilityForInternetConnection()!.isReachable()
        print(error.localizedDescription)
        var errorMessage = "error_general".localizedString
        if !isReachable {
            errorMessage = "no_internet_connection_message".localizedString
        }
        let blockedError =  error.localizedDescription == "blocked"
        if blockedError {
            errorMessage = "user_blocked_message".localizedString
        }
        let alert = UIAlertController(title: NSLocalizedString("error", comment: ""), message: errorMessage, preferredStyle: .Alert)
        let closeAction = UIAlertAction(title: NSLocalizedString("error_ok", comment: ""), style: .Default) { (action: UIAlertAction) -> Void in
            
        }
        alert.addAction(closeAction)
        if isReachable {
            let parseObject = PFObject(className: "Error")
            parseObject["owner"] = PFUser.currentUser()
            parseObject["message"] = error.localizedDescription
            parseObject["device"] = UIDevice.currentDevice().platformString()
            parseObject["appversion"] = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
            parseObject["os_version"] = UIDevice.currentDevice().systemVersion
            parseObject.saveInBackground()
        }
        presentViewController(alert, animated: true, completion: nil)
    }
}