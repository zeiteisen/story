//
//  Node.swift
//  Story
//
//  Created by Hanno Bruns on 14.01.16.
//  Copyright © 2016 Titschka. All rights reserved.
//

import Foundation
import Parse

class Node: PFObject, PFSubclassing {
    
    @NSManaged var story: String
    @NSManaged var owner: PFUser
    @NSManaged var option1: String
    @NSManaged var option2: String
    @NSManaged var next1: Node
    @NSManaged var next2: Node
    @NSManaged var likeRelation: PFRelation
    @NSManaged var lang: String
    
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    static func parseClassName() -> String {
        return "Node"
    }
}