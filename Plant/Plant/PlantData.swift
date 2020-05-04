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
    var profile: Profile
    var body: some View {
        VStack{
            image
                .resizable()
                .frame(width: 150.0, height: 150.0)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
            Text(profile.plantname)
                .font(.title)
            
        }
        
    }
}

struct PlantData_Previews: PreviewProvider {
    static var previews: some View {
        PlantData(image: Image("basil"), profile: (.default))
    }
}

