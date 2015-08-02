import UIKit

class TeaserCell: UITableViewCell {
    @IBOutlet weak var storyLabel: UILabel!
    @IBOutlet weak var countNodesLabel: UILabel!
    @IBOutlet weak var entryBarrierLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.clearColor()
    }
}
