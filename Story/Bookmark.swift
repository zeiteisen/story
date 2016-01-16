//
//  Bookmark.swift
//  Story
//
//  Created by Hanno Bruns on 16.01.16.
//  Copyright © 2016 Titschka. All rights reserved.
//

import Foundation
import Parse

class Bookmark: PFObject, PFSubclassing {
    
    @NSManaged var node: Node
    @NSManaged var owner: PFUser
    @NSManaged var story: String
    
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    static func parseClassName() -> String {
        return "Bookmark"
    }
}