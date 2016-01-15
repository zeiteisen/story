import UIKit
import Parse

enum UserState {
    case Anonymous
    case LoggedIn
    case LoggedOut
}

class MasterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var objects = [PFObject]()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var ranksButton: SmartButton!
    @IBOutlet weak var loginButton: SmartButton!
    var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        let addButton = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        ranksButton.setTitle(NSLocalizedString("ranks", comment: ""), forState: .Normal)
        loginButton.setTitle(NSLocalizedString("wait", comment: ""), forState: .Normal)
        usernameLabel.text = NSLocalizedString("wait", comment: "")
        rankLabel.text = NSLocalizedString("wait", comment: "")
        title = NSLocalizedString("start_title", comment: "")
        if (PFUser.currentUser()?.objectId == nil) {
            createAnonymousUserAndUpdate()
        }
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "updateContent", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        Ranks.getRankDescription()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateContent()
    }
    
    func shouldLogout() -> Bool {
        return PFUser.currentUser()!.authenticated && !PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()!)
    }
    
    func createAnonymousUserAndUpdate() {
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
            if let error = error {
                self.showAlertWithError(error)
            } else {
                self.updateContent()
            }
        })
    }
    
    func updateContent() {
        if shouldLogout() {
            loginButton.setTitle(NSLocalizedString("logout", comment: ""), forState: .Normal)
        } else {
            loginButton.setTitle(NSLocalizedString("signup", comment: ""), forState: .Normal)
        }
        let query = PFQuery(className: "Node")
        query.addDescendingOrder("updatedAt")
        query.whereKeyDoesNotExist("root")
        query.includeKey("owner")
        query.whereKey("lang", equalTo: NSLocale.preferredLanguages()[0])
        query.findObjectsInBackgroundWithBlock { (results: [PFObject]?, error: NSError?) -> Void in
            self.refreshControl.endRefreshing()
            if let error = error {
                self.showAlertWithError(error)
            } else if let nodes = results {
                self.objects = nodes
                self.tableView.reloadData()
                let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                    Int64(0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            }
        }
        PFUser.currentUser()?.fetchInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
            if let error = error {
                self.showAlertWithError(error)
            } else if let user = object as? PFUser {
                var username = NSLocalizedString("anonymous", comment: "")
                if let remoteUsername = user["username"] as? String {
                    if !PFAnonymousUtils.isLinkedWithUser(user) {
                        username = remoteUsername
                    }
                }
                self.usernameLabel.text = NSLocalizedString("your_name", comment: "") + " \(username)"
                let likes = PFUser.getCurrentUserLikes()
                let rankString = Ranks.getRankStringForLikes(likes)
                self.rankLabel.text = NSLocalizedString("your_rank", comment: "") + " \(rankString) " + "(\(likes))"
            }
        })
    }

    func insertNewObject(sender: AnyObject) {
        performSegueWithIdentifier("storyEditor", sender: self)
    }
    
    // MARK: - Actions 
    @IBAction func shareTouched(sender: AnyObject) {
        var sharingItems = [AnyObject]()
        sharingItems.append(NSLocalizedString("share_text", comment: ""))
//        if let image = sharingImage {
//            sharingItems.append(image)
//        }
        if let url = NSURL(string: "http://apple.co/1OIBcnw") {
            sharingItems.append(url)
        }
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func ranksTouched(sender: AnyObject) {
    }
    
    @IBAction func loginTouched(sender: UIButton) {
        if shouldLogout() {
            sender.enabled = false
            PFUser.logOutInBackgroundWithBlock({ (error: NSError?) -> Void in
                if let error = error {
                    self.showAlertWithError(error)
                } else {
                    sender.enabled = true
                    self.createAnonymousUserAndUpdate()
                }
            })
        } else {
            let signupViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            presentViewController(signupViewController, animated: true, completion: nil)
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Read" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                let controller = (segue.destinationViewController) as! ReadViewController
                controller.node = object
                controller.root = object
            }
        }
    }

    // MARK: - Table View

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TeaserCell", forIndexPath: indexPath) as! TeaserCell
        let object = objects[indexPath.row]
        cell.storyLabel.text = object["story"] as? String
        if let countNodes = object["countNodes"] as? NSNumber {
            cell.countNodesLabel.text = NSLocalizedString("count_nodes", comment: "") + " \(countNodes.integerValue)"
        }
        if let entryBarrier = object["entryBarrier"] as? NSNumber {
            let rankString = Ranks.getRankStringForLikes(entryBarrier.integerValue)
            cell.entryBarrierLabel.text = NSLocalizedString("enty_barrier", comment: "") + " \(rankString)" + "(\(entryBarrier.integerValue))"
        }
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("Read", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}

