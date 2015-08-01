import UIKit
import Parse

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func closeTouched(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func signupTouched(sender: AnyObject) {
        if let user = PFUser.currentUser() {
            user.username = usernameInput.text
            user.password = passwordInput.text
            user.signUpInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                if let error = error {
                    
                } else {
                    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        }
    }
}
