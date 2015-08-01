import UIKit
import Parse

class ReadViewController: UIViewController {

    var node: PFObject!
    var selectedOption1 = true
    
    @IBOutlet weak var storyLabel: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var writtebByLabel: UILabel!
    @IBOutlet weak var likeButton: SmartButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLabelsWithNode(node)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "storyEditor" {
            let target = segue.destinationViewController as! EditViewController
            target.node = node
            target.option1 = selectedOption1
        }
    }
    
    func setLabelsWithNode(node: PFObject) {
        likeButton.hidden = false
        storyLabel.text = node["story"] as? String
        var userName = NSLocalizedString("unknown", comment: "")
        if let owner = node["owner"] as? PFUser {
            if let realUserName = owner["username"] as? String {
                userName = realUserName
            }
            
            if let user = PFUser.currentUser() {
                if owner.objectId! == user.objectId {
                    likeButton.hidden = true
                }
            }
        }
        
        likeButton.enabled = false
        if !likeButton.hidden {
            let query = PFQuery(className: "Node")
            query.whereKey("objectId", equalTo: node.objectId!)
            query.whereKey("likesRelation", equalTo: PFUser.currentUser()!)
            query.findObjectsInBackgroundWithBlock { (results: [AnyObject]?, error: NSError?) -> Void in
                if let error = error {
                    // do nothing
                } else if results?.count > 0 {
                    self.likeButton.backgroundColor = UIColor.getColorForAlreadyLiked()
                } else {
                    self.likeButton.enabled = true
                }
            }
        }
        
        writtebByLabel.text = NSLocalizedString("written_by", comment: "") + " \(userName)"
        button1.setTitle(node["option1"] as? String, forState: .Normal)
        button2.setTitle(node["option2"] as? String, forState: .Normal)
    }
    
    func updateContentWithNext(next: PFObject) {
        let query = PFQuery(className: "Node")
        query.whereKey("objectId", equalTo: next.objectId!)
        query.includeKey("owner")
        button1.enabled = false
        button2.enabled = false
        likeButton.enabled = false
        query.findObjectsInBackgroundWithBlock({ (results: [AnyObject]?, error: NSError?) -> Void in
            self.button1.enabled = true
            self.button2.enabled = true
            self.likeButton.enabled = true
            if let error = error {
                println("error: \(error)")
            } else if let results = results as? Array<PFObject> {
                let next = results.first!
                self.node = next
                self.setLabelsWithNode(next)
            }
        })
    }
    
    // MARK: - Actions
    
    @IBAction func likeTouched(sender: UIButton) {
        if let nodeObjectId = node.objectId {
            PFCloud.callFunctionInBackground("like", withParameters: ["node": nodeObjectId], block: { (result: AnyObject?, error: NSError?) -> Void in
                if let error = error {
                    sender.enabled = true
                } else {
                    sender.enabled = false
                    sender.backgroundColor = UIColor.getColorForAlreadyLiked()
                }
            })
        }
    }
    
    @IBAction func button1Touched(sender: AnyObject) {
        selectedOption1 = true
        if let next = node["next1"] as? PFObject {
            updateContentWithNext(next)
        } else {
            performSegueWithIdentifier("storyEditor", sender: self)
        }
    }
    
    @IBAction func button2Touched(sender: AnyObject) {
        selectedOption1 = false
        if let next = node["next2"] as? PFObject {
            updateContentWithNext(next)
        } else {
            performSegueWithIdentifier("storyEditor", sender: self)
        }
    }
}
