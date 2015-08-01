import UIKit
import Parse

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func closeTouched(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func loginTouched(sender: AnyObject) {
        login()
    }
    
    @IBAction func signupTouched(sender: AnyObject) {
        if let user = PFUser.currentUser() {
            
            user.username = usernameInput.text
            user.password = passwordInput.text
            user.signUpInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                if let error = error {
                    
                } else {
                    self.login() // use this workaround to refresh the session when going from anonymous to normal user
                }
            })
        }
    }
    
    func login() {
        PFUser.logInWithUsernameInBackground(self.usernameInput.text, password: self.passwordInput.text, block: { (user: PFUser?, error: NSError?) -> Void in
            if let error = error {
                
            } else {
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }
}
