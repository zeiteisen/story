import UIKit
import Parse

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardNotification:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        usernameLabel.text = NSLocalizedString("login_intro", comment: "")
        usernameInput.placeholder = NSLocalizedString("username", comment: "")
        passwordInput.placeholder = NSLocalizedString("password", comment: "")
    }
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            let duration:NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            self.bottomConstraint?.constant = endFrame?.size.height ?? 0.0
            self.bottomConstraint.constant += 8
            UIView.animateWithDuration(duration,
                delay: NSTimeInterval(0),
                options: animationCurve,
                animations: { self.view.layoutIfNeeded() },
                completion: nil)
        }
    }
    
    func disableButtons() {
        signupButton.enabled = false
        closeButton.enabled = false
        loginButton.enabled = false
    }
    
    func enableButtons() {
        signupButton.enabled = true
        closeButton.enabled = true
        loginButton.enabled = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        usernameInput.becomeFirstResponder()
    }

    @IBAction func closeTouched(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func loginTouched(sender: AnyObject) {
        disableButtons()
        login()
    }
    
    @IBAction func signupTouched(sender: AnyObject) {
        disableButtons()
        if let user = PFUser.currentUser() {
            
            user.username = usernameInput.text
            user.password = passwordInput.text
            user.signUpInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                if let error = error {
                    self.enableButtons()
                    UIAlertController.showAlertWithError(error)
                } else {
                    self.login() // use this workaround to refresh the session when going from anonymous to normal user
                }
            })
        }
    }
    
    func login() {
        PFUser.logInWithUsernameInBackground(self.usernameInput.text!, password: self.passwordInput.text!, block: { (user: PFUser?, error: NSError?) -> Void in
            if let error = error {
                self.enableButtons()
                UIAlertController.showAlertWithError(error)
            } else {
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }
}
