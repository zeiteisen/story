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
import MBProgressHUD

class ViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var mainHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var upperHalfHeightConstraint: NSLayoutConstraint!
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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bookmarkTitleLabel: UILabel!
    @IBOutlet weak var navigationView: UIView!
    
    private var currentNode: Node?
    private var option1 = false
    private var dataSource = [Bookmark]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTextView.text = ""
        option1TextView.text = ""
        option2TextView.text = ""
        authorLabel.text = ""
        centerBarButton.setTitle("", forState: .Normal)
        tableView.tableFooterView = UIView(frame: CGRectZero)
        bookmarkTitleLabel.text = "bookmark_title".localizedString
        setupHeightConstraints(UIScreen.mainScreen().bounds.size)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        setReadOnly()
        updateUserState()
        backButton.setTitle("back_button_title".localizedString, forState: .Normal)
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            messageTextView.layoutManager.allowsNonContiguousLayout = false
            option1TextView.layoutManager.allowsNonContiguousLayout = false
            option2TextView.layoutManager.allowsNonContiguousLayout = false
            scrollView.pagingEnabled = false
        }
    }
    
    func setupHeightConstraints(size: CGSize) {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let upper = size.height / 3.0
            upperHalfHeightConstraint.constant = upper
            mainHeightConstraint.constant = size.height - upper
        } else {
            mainHeightConstraint.constant = size.height
        }
    }
    
    func updateUserState() {
        PFUser.currentUser()?.saveInBackground().continueWithSuccessBlock({ (task: BFTask) -> AnyObject? in
            return PFUser.currentUser()?.fetchInBackground()
        }).continueWithSuccessBlock({ (task: BFTask) -> AnyObject? in
            let user = task.result as! PFUser
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateAccountLabel(user)
            })
            let bookmarkQuery = Bookmark.query()!
            bookmarkQuery.whereKey("owner", equalTo: user)
            bookmarkQuery.includeKey("node")
            return bookmarkQuery.findObjectsInBackground()
        }).continueWithBlock({ (task: BFTask) -> AnyObject? in
            if let error = task.error {
                self.showAlertWithError(error)
            } else if let bookmarks = task.result as? [Bookmark] {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.dataSource.removeAll()
                    for bookmark in bookmarks {
                        if bookmark.node.objectId != nil {
                            self.dataSource.append(bookmark)
                        }
                    }
                    self.tableView.reloadData()
                    var initNodeObjectId = PFConfig.getRootObjectId()
                    if let savedInitNodeObjectId = PFUser.currentUser()!.objectForKey("lastVisitedNode") as? String {
                        initNodeObjectId = savedInitNodeObjectId
                    }
                    self.updateContentWithNextObjectId(initNodeObjectId)
                })
            }
            self.scrollView.setContentOffset(CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentSize.height - self.scrollView.bounds.size.height), animated: true)
            return nil
        })
    }
    
    func goBack() {
        if let node = currentNode {
            let next1Query = PFQuery(className: "Node")
            next1Query.whereKey("next1", equalTo: node)
            let next2Query = PFQuery(className: "Node")
            next2Query.whereKey("next2", equalTo: node)
            let orQuery = PFQuery.orQueryWithSubqueries([next1Query, next2Query])
            orQuery.includeKey("owner")
            backButton.enabled = false
            orQuery.getFirstObjectInBackgroundWithBlock({ (result: PFObject?, error: NSError?) -> Void in
                self.backButton.enabled = true
                if let error = error {
                    self.showAlertWithError(error)
                } else if let backNode = result as? Node {
                    self.updateContentWithNode(backNode)
                }
            })
        }
    }
    
    func alreadyBookmarked(node: Node) -> Bool {
        for bookmark in dataSource {
            if node.objectId == bookmark.node.objectId {
                return true
            }
        }
        return false
    }
    
    func updateAccountLabel(user: PFUser) {
        var username = NSLocalizedString("anonymous", comment: "")
        if let remoteUsername = user["username"] as? String {
            if !PFAnonymousUtils.isLinkedWithUser(user) {
                username = remoteUsername
            }
        }
        let likes = PFUser.getCurrentUserLikes()
        let rankString = Ranks.getRankStringForLikes(likes)
        self.centerBarButton.setTitle("\(username), \(rankString)(\(likes))", forState: .Normal)
    }
    
    func updateContentWithNode(node: Node) {
        setReadOnly()
        currentNode = node
        messageTextView.text = node.story
        option1TextView.text = node.option1
        option2TextView.text = node.option2
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
            } else {
                rightBarButto.hidden = false
            }
        }
        rightBarButto.enabled = false
        if !rightBarButto.hidden {
            let query = PFQuery(className: "Node")
            query.whereKey("objectId", equalTo: node.objectId!)
            query.whereKey("likesRelation", equalTo: PFUser.currentUser()!)
            query.findObjectsInBackgroundWithBlock({ (results: [PFObject]?, error: NSError?) -> Void in
                if let error = error {
                    self.showAlertWithError(error)
                } else if results?.count > 0 {
                    self.rightBarButto.enabled = false
                } else {
                    self.rightBarButto.enabled = true
                }
            })
        }
        if node.objectId == PFConfig.getRootObjectId() {
            backButton.enabled = false
        } else {
            backButton.enabled = true
        }
        if alreadyBookmarked(node) {
            leftBarButton.enabled = false
        } else {
            leftBarButton.enabled = true
        }
    }
    
    func setWriteable() {
        messageTextView.editable = true
        option1TextView.editable = true
        option2TextView.editable = true
        authorLabelHeightConstraint.constant = 0
        rightBarButto.hidden = false
        rightBarButto.enabled = true
        rightBarButto.setBackgroundImage(UIImage(named: "save"), forState: .Normal)
        rightBarButto.removeTarget(self, action: "touchLike:", forControlEvents: .TouchUpInside)
        rightBarButto.addTarget(self, action: "touchSave:", forControlEvents: .TouchUpInside)
        leftBarButton.enabled = false
        backButton.enabled = true
        messageTextView.becomeFirstResponder()
    }
    
    func setReadOnly() {
        messageTextView.editable = false
        option1TextView.editable = false
        option2TextView.editable = false
        var offset: CGFloat = 21
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            offset = 35
        }
        authorLabelHeightConstraint.constant = offset
        rightBarButto.setBackgroundImage(UIImage(named: "like"), forState: .Normal)
        rightBarButto.removeTarget(self, action: "touchSave:", forControlEvents: .TouchUpInside)
        rightBarButto.addTarget(self, action: "touchLike:", forControlEvents: .TouchUpInside)
        updateBookmarkButton()
        view.endEditing(true)
    }
    
    func updateBookmarkButton() {
        if let node = currentNode {
            if !alreadyBookmarked(node) {
                leftBarButton.enabled = true
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        setupHeightConstraints(size)
        view.layoutIfNeeded()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            let screenHeight = UIScreen.mainScreen().bounds.height
            let keyboardHeight = screenHeight - keyboardFrame.origin.y
            mainHeightConstraint.constant = UIScreen.mainScreen().bounds.height - keyboardHeight
            bottomConstraint.constant = keyboardHeight
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                delay(0.3) {
                    self.scrollView.setContentOffset(CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentSize.height - self.scrollView.bounds.size.height), animated: true)
                }
                if keyboardHeight == 0 {
                    setupHeightConstraints(UIScreen.mainScreen().bounds.size)
                }
            }
        }
    }
    
    func updateContentWithNextObjectId(nextObjectId: String?) {
        setReadOnly()
        if let next = nextObjectId {
            let query = PFQuery(className: "Node")
            query.whereKey("objectId", equalTo: next)
            query.includeKey("owner")
            MBProgressHUD.showHUDAddedTo(view, animated: true)
            query.getFirstObjectInBackgroundWithBlock { (result: PFObject?, error: NSError?) -> Void in
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                if let error = error {
                    self.showAlertWithError(error)
                } else if let result = result as? Node {
                    PFUser.currentUser()!.setObject(result.objectId!, forKey: "lastVisitedNode")
                    PFUser.currentUser()!.saveInBackground()
                    self.updateContentWithNode(result)
                }
            }
        }
    }
    
    func updateContentWithPreview(story: String?, choise: String?) {
        setWriteable()
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
        var messagePlaceholder = "message_placeholder".localizedString
        messagePlaceholder = messagePlaceholder.stringByReplacingString("#story#", with: lStory)
        messagePlaceholder = messagePlaceholder.stringByReplacingString("#choise#", with: lChoise)
        messageTextView.placeholder = messagePlaceholder
        option1TextView.placeholder = "option_1_placeholder".localizedString
        option2TextView.placeholder = "option_2_placeholder".localizedString
    }
    
    func shouldLogout() -> Bool {
        return PFUser.currentUser()!.authenticated && !PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()!)
    }
    
    func createAnonymousUserAndUpdate(completion: () -> ()) {
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
            if let error = error {
                self.showAlertWithError(error)
            } else {
                completion()
                self.updateAccountLabel(PFUser.currentUser()!)
            }
        })
    }
    
    func login(username: String, password: String, completion: ((PFUser) -> ())?) {
        PFUser.logInWithUsernameInBackground(username, password: password, block: { (user: PFUser?, error: NSError?) -> Void in
            if let error = error {
                self.showAlertWithError(error)
            } else if let user = user {
                completion?(user)
            }
        })
    }
    
    // MARK: - Actions
    @IBAction func touchBack(sender: AnyObject) {
        if messageTextView.editable {
            updateContentWithNode(currentNode!)
        } else {
            goBack()
        }
    }
    
    @IBAction func touchLeftBarButton(sender: AnyObject) {
        if let node = currentNode {
            let bookmark = Bookmark()
            bookmark.node = node
            bookmark.owner = PFUser.currentUser()!
            bookmark.story = node.story
            self.leftBarButton.enabled = false
            bookmark.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    self.dataSource.append(bookmark)
                    self.tableView.reloadData()
                } else {
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        self.scrollView.contentOffset = CGPointMake(0, self.tableView.frame.origin.y + 16)
                        }, completion: { (finished: Bool) -> Void in
                            self.delay(0.3) {
                                self.dataSource.append(bookmark)
                                self.tableView.reloadData()
                                self.delay(0.7) {
                                    self.scrollView.setContentOffset(CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentSize.height - self.scrollView.bounds.size.height), animated: true)
                                }
                            }
                    })
                }
            })
        }
    }
    
    @IBAction func touchAccount(sender: AnyObject) {
        var accountMessage = "account_anonymous_message".localizedString
        if shouldLogout() {
            accountMessage = "account_logged_in_message".localizedString
        }
        let alert = UIAlertController(title: "account_title".localizedString, message: accountMessage, preferredStyle: .Alert)
        let loginAction = UIAlertAction(title: "account_login".localizedString, style: .Default) { (action: UIAlertAction) -> Void in
            let loginAlert = UIAlertController(title: "login_title".localizedString, message: "login_message".localizedString, preferredStyle: .Alert)
            loginAlert.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
                textField.placeholder = "enter_username_placeholder".localizedString
            })
            loginAlert.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
                textField.placeholder = "enter_password_placeholder".localizedString
                textField.secureTextEntry = true
            })
            let registerAction = UIAlertAction(title: "login_button".localizedString, style: .Default, handler: { (action: UIAlertAction) -> Void in
                let userNameTextField = loginAlert.textFields?.first
                let passwordTextField = loginAlert.textFields?.last
                var username = ""
                if let textFieldUserName = userNameTextField?.text {
                    username = textFieldUserName
                }
                var password = ""
                if let textFieldPassword = passwordTextField!.text {
                    password = textFieldPassword
                }
                self.login(username, password: password, completion: { (user: PFUser) -> () in
                    self.updateAccountLabel(user)
                    if let node = self.currentNode {
                        self.updateContentWithNode(node)
                        self.updateUserState()
                    }
                })
            })
            let registerCancel = UIAlertAction(title: "register_cancel".localizedString, style: .Cancel, handler: nil)
            loginAlert.addAction(registerAction)
            loginAlert.addAction(registerCancel)
            self.presentViewController(loginAlert, animated: true, completion: nil)
        }
        let registerAction = UIAlertAction(title: "account_register".localizedString, style: .Default) { (action: UIAlertAction) -> Void in
            let registerAlert = UIAlertController(title: "register_title".localizedString, message: "register_message".localizedString, preferredStyle: .Alert)
            registerAlert.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
                textField.placeholder = "enter_username_placeholder".localizedString
            })
            registerAlert.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
                textField.placeholder = "enter_password_placeholder".localizedString
                textField.secureTextEntry = true
            })
            let registerAction = UIAlertAction(title: "register_button".localizedString, style: .Default, handler: { (action: UIAlertAction) -> Void in
                let userNameTextField = registerAlert.textFields?.first
                let passwordTextField = registerAlert.textFields?.last
                if let user = PFUser.currentUser() {
                    var username = ""
                    if let textFieldUserName = userNameTextField?.text {
                        username = textFieldUserName
                    }
                    var password = ""
                    if let textFieldPassword = passwordTextField!.text {
                        password = textFieldPassword
                    }
                    user.username = username
                    user.password = password
                    user.signUpInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                        if let error = error {
                            self.showAlertWithError(error)
                        } else {
                            self.login(username, password: password, completion: { (user: PFUser) -> () in
                                self.updateAccountLabel(user)
                                if let node = self.currentNode {
                                    self.updateContentWithNode(node)
                                }
                            })
                        }
                    })
                }
            })
            let registerCancel = UIAlertAction(title: "register_cancel".localizedString, style: .Cancel, handler: nil)
            registerAlert.addAction(registerAction)
            registerAlert.addAction(registerCancel)
            self.presentViewController(registerAlert, animated: true, completion: nil)
        }
        let ranksAction = UIAlertAction(title: "account_show_ranks".localizedString, style: .Default) { (action: UIAlertAction) -> Void in
            let ranksAlert = UIAlertController(title: "ranks_description".localizedString, message: Ranks.getRankDescription(), preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "ranks_cancel".localizedString, style: .Cancel, handler: nil)
            ranksAlert.addAction(cancelAction)
            self.presentViewController(ranksAlert, animated: true, completion: nil)
        }
        let logoutAction = UIAlertAction(title: "account_logout".localizedString, style: .Default) { (action: UIAlertAction) -> Void in
            PFUser.logOutInBackgroundWithBlock({ (error: NSError?) -> Void in
                if let error = error {
                    self.showAlertWithError(error)
                } else {
                    self.createAnonymousUserAndUpdate({ () -> () in
                        if let node = self.currentNode {
                            self.updateContentWithNode(node)
                            self.updateUserState()
                        }
                    })
                }
            })
        }
        let cancel = UIAlertAction(title: "account_cancel".localizedString, style: .Cancel, handler: nil)
        if shouldLogout() {
            alert.addAction(logoutAction)
        } else {
            alert.addAction(loginAction)
            alert.addAction(registerAction)
        }
        alert.addAction(ranksAction)
        alert.addAction(cancel)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func touchLike(sender: UIButton) {
        print("like")
        if let node = currentNode {
            PFCloud.callFunctionInBackground("like", withParameters: ["node": node.objectId!], block: { (result: AnyObject?, error: NSError?) -> Void in
                if let error = error {
                    sender.enabled = true
                    self.showAlertWithError(error)
                } else {
                    sender.enabled = false
                }
            })
        }

    }
    
    func touchSave(sender: AnyObject) {
        if messageTextView.text != "" && option1TextView.text != "" && option2TextView.text != "" {
            if currentNode == nil {
                return
            }
            
            
            let object = Node()
            object.story = messageTextView.text
            object.option1 = option1TextView.text
            object.option2 = option2TextView.text
            object.owner = PFUser.currentUser()!
            object.lang = "lang".localizedString
            object.depth = currentNode!.depth.integerValue + 1
            rightBarButto.enabled = false
            object.saveInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                self.rightBarButto.enabled = true
                if let error = error {
                    self.showAlertWithError(error)
                } else {
                    if let node = self.currentNode {
                        if self.option1 {
                            node.setObject(object, forKey: "next1")
                        } else {
                            node.setObject(object, forKey: "next2")
                        }
                        self.rightBarButto.enabled = false
                        node.saveInBackgroundWithBlock({ (finished: Bool, error: NSError?) -> Void in
                            self.rightBarButto.enabled = true
                            if let error = error {
                                self.showAlertWithError(error)
                            } else {
                                self.view.endEditing(true)
                                self.updateContentWithNode(object)
                            }
                        })
                    } else {
                        self.updateContentWithNode(object)
                    }
                }
            })
        } else {
            if messageTextView.text == "" {
                messageTextView.shake()
            }
            if option1TextView.text == "" {
                option1TextView.shake()
            }
            if option2TextView.text == "" {
                option2TextView.shake()
            }
        }
    }
    
    @IBAction func touchOption1(sender: AnyObject) {
        option1 = true
        if currentNode?.objectForKey("next1") == nil {
            updateContentWithPreview(currentNode?.story, choise: currentNode?.option1)
        } else {
            updateContentWithNextObjectId(currentNode?.next1.objectId)
        }

    }
    
    @IBAction func touchOption2(sender: AnyObject) {
        option1 = false
        if currentNode?.objectForKey("next2") == nil {
            updateContentWithPreview(currentNode?.story, choise: currentNode?.option2)
        } else {
            updateContentWithNextObjectId(currentNode?.next2.objectId)
        }
    }
    
    // MARK: - TableViewDataSource
        
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            print("delete")
            let bookmark = dataSource[indexPath.row]
            bookmark.deleteInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                if let error = error {
                    self.showAlertWithError(error)
                } else {
                    self.dataSource.removeAtIndex(indexPath.row)
                    self.tableView.reloadData()
                    self.updateBookmarkButton()
                }
            })
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let bookmark = dataSource[indexPath.row]
        updateContentWithNextObjectId(bookmark.node.objectId)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! BookmarkCell
        cell.backgroundColor = UIColor.clearColor()
        cell.contentView.backgroundColor = UIColor.clearColor()
        let bookmark = dataSource[indexPath.row]
        cell.label.text = bookmark.story
        let depth = bookmark.node.depth
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        let dateString = formatter.stringFromDate(bookmark.createdAt!)
        var subTitleString = "bookmark_subtitle".localizedString
        subTitleString = subTitleString.stringByReplacingString("#depth#", with: "\(depth)")
        subTitleString = subTitleString.stringByReplacingString("#date#", with: dateString)
        cell.subTitle.text = subTitleString
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return 80
        } else {
            return 60
        }
    }
    
    // MARK: - ScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
}
