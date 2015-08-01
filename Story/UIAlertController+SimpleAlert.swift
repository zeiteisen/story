import UIKit

extension UIAlertController {
    class func showAlertWithError(error: NSError) {
        let alert = UIAlertController(title: NSLocalizedString("error", comment: ""), message: error.localizedDescription, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .Default) { (action: UIAlertAction!) -> Void in
            
        }
        alert.addAction(alertAction)
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
}