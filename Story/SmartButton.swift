import UIKit

class SmartButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel?.lineBreakMode = .ByWordWrapping
        titleLabel?.textAlignment = .Center
    }
    
    override func intrinsicContentSize() -> CGSize {
        let size = titleLabel?.intrinsicContentSize() ?? CGSizeZero
        return CGSizeMake(size.width + titleEdgeInsets.left + titleEdgeInsets.right, size.height + titleEdgeInsets.top + titleEdgeInsets.bottom + 16)
    }
}
