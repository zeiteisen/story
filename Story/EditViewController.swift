import UIKit
import Parse

class EditViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var storyTextView: SZTextView!
    @IBOutlet weak var option1TextView: SZTextView!
    @IBOutlet weak var option2TextView: SZTextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var node: PFObject?
    var option1: Bool?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardNotification:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        storyTextView.placeholder = NSLocalizedString("continue_story", comment: "")
        option1TextView.placeholder = NSLocalizedString("option_1", comment: "")
        option2TextView.placeholder = NSLocalizedString("option_2", comment: "")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        storyTextView.becomeFirstResponder()
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
    
    // MARK: - Actions
    
    @IBAction func saveTouched(sender: AnyObject) {
        if storyTextView.text != "" && option1TextView.text != "" && option2TextView.text != "" {
            let object = PFObject(className: "Node")
            object.setObject(storyTextView.text, forKey: "story")
            object.setObject(option1TextView.text, forKey: "option1")
            object.setObject(option2TextView.text, forKey: "option2")
            object.setObject(PFUser.currentUser()!, forKey: "owner")
            if let node = self.node {
                object.setObject(false, forKey: "root")
            } else {
                object.setObject(true, forKey: "root")
            }
            saveButton.enabled = false
            object.saveInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                if let error = error {
                    self.saveButton.enabled = true
                    println("error saving object: \(error)")
                } else {
                    if let node = self.node, option1 = self.option1 {
                        if option1 {
                            node.setObject(object, forKey: "next1")
                        } else {
                            node.setObject(object, forKey: "next2")
                        }
                        node.saveInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                            if let error = error {
                                self.saveButton.enabled = false
                                println("error saving object: \(error)")
                            } else {
                                self.navigationController?.popToRootViewControllerAnimated(true)
                            }
                        })
                    } else {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                }
            })
        }
    }
    
    @IBAction func scrollviewTouched(sender: AnyObject) {
        view.endEditing(true)
    }
    
    // MARK: - TextViewDelegate
    
    func textViewDidEndEditing(textView: UITextView) {
        textView.resignFirstResponder()
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
}
