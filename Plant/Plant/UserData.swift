//
//  UserData.swift
//  Plant
//
//  Created by Michael Park on 4/27/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI
import Combine

// Tells xcode that UserData (holds profile) can change at any time (Needed for debugging)
final class UserData: ObservableObject {
    @Published var profile = Profile.default
}
