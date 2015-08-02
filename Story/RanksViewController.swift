import UIKit

class RanksViewController: UIViewController {
    
    @IBOutlet weak var ranksLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("ranks", comment: "")
//        ranksLabel.text = NSLocalizedString("ranks_description", comment: "")
        ranksLabel.text = Ranks.getRankDescription()
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
