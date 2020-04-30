//
//  SettingsData.swift
//  Plant
//
//  Created by Michael Park on 4/27/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import Foundation

struct Profile {
    var username: String
    var prefersNotifications: Bool
    var plantname: String
    
    static let `default` = Self(username: "planter", prefersNotifications: true, plantname: "greenboi")
    
    init(username: String, prefersNotifications: Bool = true, plantname: String) {
        self.username = username
        self.prefersNotifications = prefersNotifications
        self.plantname = plantname;
    }

}
