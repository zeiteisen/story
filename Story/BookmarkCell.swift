//
//  BookmarkCell.swift
//  Story
//
//  Created by Hanno Bruns on 16.01.16.
//  Copyright © 2016 Titschka. All rights reserved.
//

import UIKit

class BookmarkCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var styleView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        styleView.layer.cornerRadius = 10
    }
}
