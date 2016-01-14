//
//  ViewController.swift
//  Story
//
//  Created by Hanno Bruns on 14.01.16.
//  Copyright © 2016 Titschka. All rights reserved.
//

import UIKit
import Parse
import UITextView_Placeholder

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var mainHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var option1TextView: UITextView!
    @IBOutlet weak var option2TextView: UITextView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftBarButton: UIButton!
    @IBOutlet weak var centerBarButton: UIButton!
    @IBOutlet weak var rightBarButto: UIButton!
    
    private var currentNode: Node?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainHeightConstraint.constant = UIScreen.mainScreen().bounds.height
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        setReadOnly()
        PFUser.currentUser()?.saveInBackground().continueWithSuccessBlock({ (task: BFTask) -> AnyObject? in
            return PFUser.currentUser()?.fetchInBackground()
        }).continueWithBlock({ (task: BFTask) -> AnyObject? in
            if let error = task.error {
                UIAlertController.showAlertWithError(error)
            } else if let user = task.result as? PFUser {
                var username = NSLocalizedString("anonymous", comment: "")
                if let remoteUsername = user["username"] as? String {
                    if !PFAnonymousUtils.isLinkedWithUser(user) {
                        username = remoteUsername
                    }
                }
                let likes = PFUser.getCurrentUserLikes()
                let rankString = Ranks.getRankStringForLikes(likes)
                self.centerBarButton.setTitle("\(username), \(rankString)(\(likes))", forState: .Normal)
                let rootObjectId = "8pkoWzwlCG"
                self.updateContentWithNextObjectId(rootObjectId)
            }
            return nil
        })
    }
    
    func updateContentWithNode(node: Node) {
        self.currentNode = node
        self.messageTextView.text = node.story
        self.option1TextView.text = node.option1
        self.option2TextView.text = node.option2
        var userName = NSLocalizedString("unknown", comment: "")
        if let realUserName = node.owner["username"] as? String {
            userName = realUserName
        }
        var likes: NSNumber = 0
        if let remoteLikes = node.owner["likes"] as? NSNumber {
            likes = remoteLikes
        }
        let rankString = Ranks.getRankStringForLikes(likes.integerValue)
        self.authorLabel.text = NSLocalizedString("written_by", comment: "") + " \(userName), \(rankString)(\(likes))"

        if let user = PFUser.currentUser() {
            if node.owner.objectId! == user.objectId {
                rightBarButto.hidden = true
            }
        }
        rightBarButto.enabled = false
        rightBarButto.backgroundColor = UIColor.getColorForTouchableArea()
        if !rightBarButto.hidden {
            let query = PFQuery(className: "Node")
            query.whereKey("objectId", equalTo: node.objectId!)
            query.whereKey("likesRelation", equalTo: PFUser.currentUser()!)
            query.findObjectsInBackgroundWithBlock({ (results: [PFObject]?, error: NSError?) -> Void in
                if let error = error {
                    UIAlertController.showAlertWithError(error)
                } else if results?.count > 0 {
                    self.rightBarButto.backgroundColor = UIColor.getColorForAlreadyLiked()
                } else {
                    self.rightBarButto.enabled = true
                }
            })
        }

    }
    
    func setWriteable() {
        messageTextView.editable = true
        option1TextView.editable = true
        option2TextView.editable = true
        authorLabelHeightConstraint.constant = 0
        messageTextView.becomeFirstResponder()
        rightBarButto.setTitle("save".localizedString, forState: .Normal)
        rightBarButto.removeTarget(self, action: "touchLike:", forControlEvents: .TouchUpInside)
        rightBarButto.addTarget(self, action: "touchSave:", forControlEvents: .TouchUpInside)
    }
    
    func setReadOnly() {
        messageTextView.editable = false
        option1TextView.editable = false
        option2TextView.editable = false
        authorLabelHeightConstraint.constant = 21
        rightBarButto.setTitle("like", forState: .Normal)
        rightBarButto.removeTarget(self, action: "touchSave:", forControlEvents: .TouchUpInside)
        rightBarButto.addTarget(self, action: "touchLike:", forControlEvents: .TouchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.setContentOffset(CGPointMake(scrollView.contentOffset.x, scrollView.contentSize.height - scrollView.bounds.size.height), animated: false)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        mainHeightConstraint.constant = size.height
        view.layoutIfNeeded()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            let screenHeight = UIScreen.mainScreen().bounds.height
            let keyboardHeight = screenHeight - keyboardFrame.origin.y
            mainHeightConstraint.constant = UIScreen.mainScreen().bounds.height - keyboardHeight
            bottomConstraint.constant = keyboardHeight
        }
    }
    
    func updateContentWithNextObjectId(nextObjectId: String?) {
        if let next = nextObjectId {
            let query = PFQuery(className: "Node")
            query.whereKey("objectId", equalTo: next)
            query.includeKey("owner")
            query.getFirstObjectInBackgroundWithBlock { (result: PFObject?, error: NSError?) -> Void in
                if let error = error {
                    UIAlertController.showAlertWithError(error)
                } else if let result = result as? Node {
                    self.updateContentWithNode(result)
                }
            }
        }
    }
    
    func updateContentWithPreview(story: String?, choise: String?) {
        messageTextView.text = ""
        option1TextView.text = ""
        option2TextView.text = ""
        var lStory = ""
        if let remoteStory = story {
            lStory = remoteStory
        }
        var lChoise = ""
        if let remoteChoise = choise {
            lChoise = remoteChoise
        }
        messageTextView.placeholder = "Führe die Geschichte fort:\nLetzter Part: \(lStory)\nDeine Auswahl: \(lChoise)"
        option1TextView.placeholder = "Trage Option 1 ein"
        option2TextView.placeholder = "Trage Option 2 ein"
    }
    
    // MARK: - Actions
    
    func touchLike(sender: UIButton) {
        print("like")
        if let node = currentNode {
            PFCloud.callFunctionInBackground("like", withParameters: ["node": node.objectId!], block: { (result: AnyObject?, error: NSError?) -> Void in
                if let error = error {
                    sender.enabled = true
                    UIAlertController.showAlertWithError(error)
                } else {
                    sender.enabled = false
                    sender.backgroundColor = UIColor.getColorForAlreadyLiked()
                }
            })
        }

    }
    
    func touchSave(sender: AnyObject) {
        print("save")
        view.endEditing(true)
    }
    
    @IBAction func touchOption1(sender: AnyObject) {
        print("option1")
        if currentNode?.next1 == nil {
            setWriteable()
            updateContentWithPreview(currentNode?.story, choise: currentNode?.option1)
        } else {
            setReadOnly()
            updateContentWithNextObjectId(currentNode?.next1.objectId)
        }

    }
    
    @IBAction func touchOption2(sender: AnyObject) {
        print("option2")
        if currentNode?.next2 == nil {
            setWriteable()
            updateContentWithPreview(currentNode?.story, choise: currentNode?.option2)
        } else {
            setReadOnly()
            updateContentWithNextObjectId(currentNode?.next2.objectId)
        }
    }
}
