//
//  UserData.swift
//  Plant
//
//  Created by Michael Park on 4/27/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI
import Combine


final class UserData: ObservableObject {
    @Published var profile = Profile.default
}
