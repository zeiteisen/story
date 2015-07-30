import UIKit
import Parse

class ReadViewController: UIViewController {

    var node: PFObject!
    var selectedOption1 = true
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLabelsWithNode(node)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "storyEditor" {
            println("to the editor!")
            let target = segue.destinationViewController as! EditViewController
            target.node = node
            target.option1 = selectedOption1
        }
    }
    
    func setLabelsWithNode(node: PFObject) {
        textView.text = node["story"] as! String
        let size = textView.sizeThatFits(CGSizeMake(textView.frame.size.width, CGFloat.max))
        textViewHeightConstraint.constant = size.height
        button1.setTitle(node["option1"] as? String, forState: .Normal)
        button2.setTitle(node["option2"] as? String, forState: .Normal)
    }
    
    func updateContentWithNext(next: PFObject) {
        let query = PFQuery(className: "Node")
        query.whereKey("objectId", equalTo: next.objectId!)
        query.findObjectsInBackgroundWithBlock({ (results: [AnyObject]?, error: NSError?) -> Void in
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
