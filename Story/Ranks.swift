import Foundation

class Ranks {
    class func getRankStringForLikes(countLikes: Int) -> String {
        let ranks = NSArray(contentsOfFile: NSBundle.mainBundle().pathForResource("Ranks", ofType: "plist")!)!
        for var index = ranks.count - 1; index >= 0; --index {
            let obj: AnyObject = ranks[index]
            if let dict = obj as? NSDictionary {
                let likes = dict["likes"] as! NSNumber
                let titleKey = dict["titleKey"] as! String
                if countLikes >= likes.integerValue {
                    return NSLocalizedString(titleKey, comment: "")
                }
            }
        }
        return "error"
    }
    
    class func getRankDescription() -> String {
        let ranks = NSArray(contentsOfFile: NSBundle.mainBundle().pathForResource("Ranks", ofType: "plist")!)
        var description = ""
        for obj: AnyObject in ranks! {
            if let dict = obj as? NSDictionary {
                let likes = dict["likes"] as! NSNumber
                let titleKey = dict["titleKey"] as! String
                let title = NSLocalizedString(titleKey, comment: "")
                description += "\(title): \(likes)\n"
            }
        }
        return description
    }
    
    class func getRanksForLikes(countLikes: Int) -> Array<NSDictionary> {
        let ranks = NSArray(contentsOfFile: NSBundle.mainBundle().pathForResource("Ranks", ofType: "plist")!)!
        var retVal = Array<NSDictionary>()
        for var index = ranks.count - 1; index >= 0; --index {
            let obj: AnyObject = ranks[index]
            if let dict = obj as? NSDictionary {
                let likes = dict["likes"] as! NSNumber
                let titleKey = dict["titleKey"] as! String
                if countLikes >= likes.integerValue {
                    retVal.append(dict)
                }
            }
        }
        return retVal
    }
}