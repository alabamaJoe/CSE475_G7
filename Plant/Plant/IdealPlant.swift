//
//  IdealPlant.swift
//  Plant
//
//  Created by Michael Park on 5/22/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI

// Struct for storing the respective ideal values for a plant type
struct IdealPlant {
    var moisture: Float
    var temperature: Float
    var humidity: Float
    
    init(moisture: Float, temperature: Float, humidity: Float) {
        self.moisture = moisture
        self.temperature = temperature
        self.humidity = humidity
    }
    
}
