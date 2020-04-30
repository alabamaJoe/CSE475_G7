//
//  Home.swift
//  Plant
//
//  Created by Michael Park on 4/22/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI

struct Home: View {
    @State var openSettings = false
    @EnvironmentObject var userData: UserData
    
    let gradientColors = Gradient(colors: [.green, .blue])
    

    init(){
//        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.401, green: 0.994, blue: 0.628, alpha: 1.0)
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.753, green: 0.753, blue: 0.753, alpha: 1.0)

    }
    var settingsButton: some View {
        Button(action: { self.openSettings.toggle() }) {
            Image(systemName: "gear")
                .imageScale(.large)
                .accessibility(label: Text("Settings"))
                .padding()
        }
    }
        
    var body: some View {
        NavigationView{
            ZStack {
                RadialGradient(gradient: gradientColors, center: .center, startRadius: 2, endRadius: 650)
//                List{
                    HStack(alignment: .center){
                        Spacer()
                        PlantData(image: Image("basil"), profile: self.userData.profile)
                            .offset(x: CGFloat(0), y: CGFloat(-220))
                        Spacer()
                    }
                Text("Temp: 30° C")
                    .font(.title)
                    .position(x: 190, y: 350)
                
                Text("Moisture Level: 42%")
                    .font(.title)
                    .position(x: 190, y: 450)
                
                
//                }
            }
            .navigationBarTitle("Hello, \(self.userData.profile.username)")
            .navigationBarItems(trailing:settingsButton)
            .sheet(isPresented: $openSettings){
                SettingsView()
                    .environmentObject(self.userData)

            }
        }
    }
}
 

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home().environmentObject(UserData())
    }
}
