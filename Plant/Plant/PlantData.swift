//
//  PlantData.swift
//  Plant
//
//  Created by Michael Park on 4/22/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI

struct PlantData: View {
    var image: Image
    var plantName: String
    var body: some View {
        VStack{
            image
                .resizable()
                .frame(width: 200.0, height: 200.0)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
            Text(plantName)
                .font(.title)
            
        }
        
    }
}

struct PlantData_Previews: PreviewProvider {
    static var previews: some View {
        PlantData(image: Image("basil"), plantName: ("Green"))
    }
}

