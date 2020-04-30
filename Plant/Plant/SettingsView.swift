//
//  SettingsView.swift
//  Plant
//
//  Created by Michael Park on 4/27/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userData: UserData
//    @Binding var profile: Profile
    
   
    var body: some View {
        List {
            HStack {
                Text("Username").bold()
                Divider()
                TextField("Username", text: $userData.profile.username)
            }
            HStack {
                Text("Plant Name").bold()
                Divider()
                TextField("Plant Name", text: $userData.profile.plantname)
            }
            Toggle(isOn: $userData.profile.prefersNotifications) {
                Text("Enable Notifications")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(UserData())
    }
}
