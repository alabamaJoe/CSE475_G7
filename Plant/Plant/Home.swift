//
//  Home.swift
//  Plant
//
//  Created by Michael Park on 4/22/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI
import AWSS3
import AWSCore
import AWSCognito

struct Home: View {

    let timer = Timer.publish(every: 2, on: .current, in: .common).autoconnect()


    weak var label: UILabel!
    weak var activityIndicator: UIActivityIndicatorView!
    weak var imageView: UIImageView!
    weak var progressBar: UIProgressView!
    
    weak var image: UIImageView!
    @State var openSettings = false
    @EnvironmentObject var userData: UserData
    
    @State var imageData : Data = .init(capacity: 0)
    @State var show = false
    @State var imagepicker = false
    @State var source: UIImagePickerController.SourceType = .photoLibrary
    
    @ObservedObject var loader = DataLoader()
    
    
    let gradientColors = Gradient(colors: [.green, .blue])
    
    init(){
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
                NavigationLink(destination: ImagePicker(show: $imagepicker, image: $imageData, source: source), isActive: $imagepicker) {
                    Text("")
                }
                RadialGradient(gradient: gradientColors, center: .center, startRadius: 2, endRadius: 650)
                HStack(alignment: .center){
                    Spacer()
                    if self.imageData.count != 0 {
                        PlantData(image: Image(uiImage:UIImage(data: self.imageData)!), profile: self.userData.profile)
                            .offset(x: CGFloat(0), y: CGFloat(-120))
                    } else {
                        PlantData(image: Image("basil"), profile: self.userData.profile)
                            .offset(x: CGFloat(0), y: CGFloat(-120))
                    }
                    
                    Spacer()
                }
                VStack{
                    Button(action: { self.show.toggle() }) {
                        Image(systemName: "camera.circle")
                            .imageScale(.large)
                            .position(x: CGFloat(270), y: CGFloat(190))
                    }
                    Button(action: { self.loader.load() }) {
                        Image(systemName: "camera.circle")
                            .imageScale(.large)
                            .position(x: CGFloat(270), y: CGFloat(190))
                    }
                }
                VStack {
                    if (loader.data.count != 0) {
                    
                        Text("Temperature: " + String(format: "%.1f", self.loader.data[0].temperature) + " °C")
                            .font(.title)
                            .position(x: 200, y: 330)
                    } else {
                        Text("Temperature: Unavailable")
                            .font(.title)
                            .position(x: 200, y: 330)

                    }
                }
             
                VStack {
                    if (loader.data.count != 0) {
                        Text("Moisture Level: " + String(format: "%.1f", self.loader.data[0].moisture) + "%")
                            .font(.title)
                            .position(x: 200, y: 390)
                    } else {
                        Text("Moisture Level: Unavailable")
                            .font(.title)
                            .position(x: 200, y: 390)

                    }
                }
                VStack {
                    if (loader.data.count != 0) {
                      Text("Humidity: " + String(format: "%.1f", self.loader.data[0].humidity) + "%")
                            .font(.title)
                            .position(x: 200, y: 450)
                    } else {
                        Text("Humidity: Unavailable")
                            .font(.title)
                            .position(x: 200, y: 450)

                    }
  
                }

            }

            .navigationBarTitle("Hello,  \(self.userData.profile.username)")
            .navigationBarItems(trailing:settingsButton)
            .sheet(isPresented: $openSettings){
                SettingsView()
                    .environmentObject(self.userData)
            }
            .onReceive(timer) {time in
                self.loader.load()
                print("\(time)")
            }
                
            .actionSheet(isPresented: $show) {
                ActionSheet(title: Text("Take photo or choose from library"), message: Text(""), buttons: [.default(Text("Photo Library "), action: {
                        self.source = .photoLibrary
                        self.imagepicker.toggle()
                }),.default(Text("Camera"), action: {
                    self.source = .camera
                    self.imagepicker.toggle()
                })
                    
                    , .default(Text("Cancel"), action: {
                    self.show = false
                })]
                )
            }

        }

        
    }
}

struct SensorData: Codable {
    public var temperature: Float
    public var moisture: Float
    public var humidity: Float
    
    enum CodingKeys: String, CodingKey {
        case temperature = "temperature"
        case moisture = "moisture"
        case humidity = "humidity"
    }
}


struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home().environmentObject(UserData())
    }
}

struct ImagePicker : UIViewControllerRepresentable {
    @Binding var show : Bool
    @Binding var image : Data
    var source : UIImagePickerController.SourceType
    
    func makeCoordinator() -> ImagePicker.Coordinator {
        return ImagePicker.Coordinator(parent1: self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = source
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    class Coordinator : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
        var parent : ImagePicker
        init(parent1 : ImagePicker) {
            parent = parent1
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            self.parent.show.toggle()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as! UIImage
            let data = image.pngData()
            self.parent.image = data!
            self.parent.show.toggle()
        }
    }
    
}
