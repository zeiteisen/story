import UIKit
import Parse

class EditViewController: UIViewController, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var storyTextView: SZTextView!
    @IBOutlet weak var option1TextView: SZTextView!
    @IBOutlet weak var option2TextView: SZTextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var storyTitleLabel: UILabel!
    @IBOutlet weak var option1Label: UILabel!
    @IBOutlet weak var option2Label: UILabel!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var authorRankLabel: UILabel!
    
    var pickerDataSource: Array<NSDictionary>?
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
        title = NSLocalizedString("edit_title", comment: "")
        storyTitleLabel.text = NSLocalizedString("write_story_intro", comment: "")
        option1Label.text = NSLocalizedString("option_1_info", comment: "")
        option2Label.text = NSLocalizedString("option_2_info", comment: "")
        saveButton.setTitle(NSLocalizedString("save", comment: ""), forState: .Normal)
        saveBarButton.title = NSLocalizedString("save", comment: "")
        if node != nil {
            pickerHeightConstraint.constant = 0
            pickerView.hidden = true
            authorRankLabel.text = ""
        } else {
            authorRankLabel.text = NSLocalizedString("edit_author_rank_description", comment: "")
        }
        var likes = PFUser.getCurrentUserLikes()
        pickerDataSource = Ranks.getRanksForLikes(likes)
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        storyTextView.becomeFirstResponder()
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
                if let root = node["root"] as? PFObject {
                    object.setObject(root, forKey: "root")
                    root.incrementKey("countNodes")
                    root.saveInBackground()
                }
            } else {
                object.setObject(NSLocale.preferredLanguages()[0] as! String, forKey: "lang")
                object.setObject(1, forKey: "countNodes")
                let selectedRow = pickerView.selectedRowInComponent(0)
                let dict = pickerDataSource![selectedRow]
                let entryBarrier = dict["likes"] as! NSNumber
                object.setObject(entryBarrier.integerValue, forKey: "entryBarrier")
            }
            saveButton.enabled = false
            saveBarButton.enabled = false
            object.saveInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                if let error = error {
                    self.saveBarButton.enabled = true
                    self.saveButton.enabled = true
                    UIAlertController.showAlertWithError(error)
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
                                self.saveBarButton.enabled = false
                                UIAlertController.showAlertWithError(error)
                            } else {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        })
                    } else {
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
            })
        } else {
            if storyTextView.text == "" {
                storyTextView.shake()
            }
            if option1TextView.text == "" {
                option1TextView.shake()
            }
            if option2TextView.text == "" {
                option2TextView.shake()
            }
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
    
    // MARK: - PickerDelegate
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let pickerDataSource = pickerDataSource {
            return pickerDataSource.count
        }
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var title = "error";
        if let pickerDataSource = pickerDataSource {
            let dict = pickerDataSource[row]
            let rankKey = dict["titleKey"] as! String
            title = NSLocalizedString(rankKey, comment: "")
        }
        return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName:UIColor.getColorForText()])
    }
}
