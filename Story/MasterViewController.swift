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
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120

        loginButton.setTitle(NSLocalizedString("wait", comment: ""), forState: .Normal)
        title = NSLocalizedString("start_title", comment: "")
        if (PFUser.currentUser()?.objectId == nil) {
            createAnonymousUserAndUpdate()
        }
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "updateContent", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
    }
    
    func shouldLogout() -> Bool {
        return PFUser.currentUser()!.isAuthenticated() && !PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()!)
    }
    
    func createAnonymousUserAndUpdate() {
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
            if let error = error {
                
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
        query.findObjectsInBackgroundWithBlock { (results: [AnyObject]?, error: NSError?) -> Void in
            self.refreshControl.endRefreshing()
            if let error = error {
                println("error: \(error)")
            } else if let nodes = results as? [PFObject] {
                self.objects = nodes
                self.tableView.reloadData()
            }
        }
        PFUser.currentUser()?.fetchInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
            if let error = error {
                println("error: \(error)")
            } else if let user = object as? PFUser {
                var username = NSLocalizedString("anonymous", comment: "")
                if let remoteUsername = user["username"] as? String {
                    if !PFAnonymousUtils.isLinkedWithUser(user) {
                        username = remoteUsername
                    }
                }
                self.usernameLabel.text = NSLocalizedString("your_name", comment: "") + ": \(username)"
                var likes = 0
                if let remoteLikes = user["likes"] as? NSNumber {
                    likes = remoteLikes.integerValue
                }
                self.rankLabel.text = NSLocalizedString("your_rank", comment: "") + ": \(likes)"
            }
        })

    }

    func insertNewObject(sender: AnyObject) {
        performSegueWithIdentifier("storyEditor", sender: self)
    }
    
    // MARK: - Actions 
    
    @IBAction func ranksTouched(sender: AnyObject) {
    }
    
    @IBAction func loginTouched(sender: UIButton) {
        if shouldLogout() {
            sender.enabled = false
            PFUser.logOutInBackgroundWithBlock({ (error: NSError?) -> Void in
                if let error = error {
                    
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
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = objects[indexPath.row]
                let controller = (segue.destinationViewController) as! ReadViewController
                controller.node = object
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
            cell.entryBarrierLabel.text = NSLocalizedString("enty_barrier", comment: "") + " \(entryBarrier.integerValue)"
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("Read", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}

