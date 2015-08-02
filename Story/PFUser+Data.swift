import Parse

extension PFUser {
    class func getCurrentUserLikes() -> Int {
        var likes = 0
        if let remoteLikes = PFUser.currentUser()?["likes"] as? NSNumber {
            likes = remoteLikes.integerValue
        }
        return likes
    }
}
