import UIKit

class RanksViewController: UIViewController {
    
    @IBOutlet weak var ranksLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("ranks", comment: "")
        var description = NSLocalizedString("ranks_description", comment: "")
        description += "\n\n"
        description += Ranks.getRankDescription()
        ranksLabel.text = description
        /* ranks
        Editor
        Autor
        Beginner
        Lektor
        Schriftsteller
        Schreiberling
        Literat
        Verfasser
        Schriftmeister
        Verleger
*/
    }
}
