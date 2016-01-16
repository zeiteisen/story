//
//  PFConfig+Defaults.swift
//  Story
//
//  Created by Hanno Bruns on 16.01.16.
//  Copyright © 2016 Titschka. All rights reserved.
//

import Parse

extension PFConfig {
    class func getRootObjectId() -> String {
        if let value = PFConfig.currentConfig()["RootObjectId"] as? [String : String] {
            let lang = "lang".localizedString
            if let rootObjectId = value[lang] {
                return rootObjectId
            }
        }
        #if DEBUG
            return "SQ67sfwZrD"
        #else
            return "8pkoWzwlCG"
        #endif
    }
}