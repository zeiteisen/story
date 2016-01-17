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
        let lang = "lang".localizedString
        if let value = PFConfig.currentConfig()["RootObjectId"] as? [String : String] {
            if let rootObjectId = value[lang] {
                return rootObjectId
            }
        }
        #if DEBUG
            if lang == "de" {
                return "SQ67sfwZrD"
            } else {
                return "Oa25IUqNYv"
            }
        #else
            if lang == "de" {
                return "0SHz50rDVY"
            } else {
                return "e8ZnI2tWtY"
            }
        #endif
    }
}