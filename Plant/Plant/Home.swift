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
import UserNotifications

struct Home: View {

    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()

    weak var label: UILabel!
    weak var activityIndicator: UIActivityIndicatorView!
    weak var imageView: UIImageView!
    weak var progressBar: UIProgressView!
    
    weak var image: UIImageView!
    @State var openSettings = false
//    @EnvironmentObject var userData: UserData
    
    @State var imageData : Data = .init(capacity: 0)
    @State var show = false
    @State var imagepicker = false
    @State var source: UIImagePickerController.SourceType = .photoLibrary
    
    @ObservedObject var loader = DataLoader()
    @ObservedObject var loaderImage = ImageLoader()
    @ObservedObject var loaderType = TypeLoader()
    
    @State var plantImage:UIImage?
    
    @State var count = 0
    @State var plantName = "Unavailable"
    
    let idealBasil = IdealPlant(moisture: 50.0, temperature: 15.56, humidity: 50.0)
    
    let idealJade = IdealPlant(moisture: 5.0, temperature: 4.44, humidity: 50.0)
    
    let idealCactus = IdealPlant(moisture: 5.0, temperature: 18.33, humidity: 50.0)
    
    var idealBank = [String:IdealPlant]()
    
    let gradientColors = Gradient(colors: [.green, .blue])
    
    init(){
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.753, green: 0.753, blue: 0.753, alpha: 1.0)
        idealBank = ["Basil":idealBasil, "Jade":idealJade, "Cactus":idealCactus]
        plantImage = loaderImage.image
    }
        
    var body: some View {
        
        NavigationView{
            ZStack {
                NavigationLink(destination: ImagePicker(show: $imagepicker, image: $imageData, source: source), isActive: $imagepicker) {
                    Text("")
                }
                RadialGradient(gradient: gradientColors, center: .center, startRadius: 2, endRadius: 650)
                HStack(alignment: .center){
                    if (loaderType.data.count != 0) {
                        PlantData(image: Image(uiImage: loaderImage.image), plantName: self.loaderType.data[0].plantType)
                            .offset(x: CGFloat(0), y: CGFloat(-120))
                    } else {
                        PlantData(image: Image(uiImage: loaderImage.image), plantName: "Press Pi Button to ID")
                            .offset(x: CGFloat(0), y: CGFloat(-120))
                    }
                }
                HStack(alignment: .center) {
                    if (loaderType.data.count != 0) {
                        Text("Ideal Values [Temperature, Moisture]: [" + String(format: "%.1f", self.idealBank[self.loaderType.data[0].plantType]!.temperature) + " °C, " + String(format: "%.1f", self.idealBank[self.loaderType.data[0].plantType]!.moisture) + "%]")
                            .font(.caption)
                            .offset(x: CGFloat(0), y: CGFloat(10))
                    } else {
                        Text("Ideal Values")
                            .font(.caption)
                            .offset(x: CGFloat(0), y: CGFloat(10))
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
                                                Text("\(self.count)")
                    } else {
                        Text("Humidity: Unavailable")
                            .font(.title)
                            .position(x: 200, y: 450)
                    }
                }
            }
            .navigationBarTitle("Hello, Planter")
            .onAppear(perform: {
                
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge,.sound,.alert]) { (_, _) in
                }
            })
            .onReceive(timer) {time in
                self.loader.load()
                self.loaderImage.load()
                self.loaderType.load()
                print("\(time)")
                self.count += 1
                
                if (self.loaderType.data.count != 0) {
                    if (self.loader.data[0].moisture < self.idealBank[self.loaderType.data[0].plantType]!.moisture) {
                        self.notifyWater()
                    }
                    
                    if (self.loader.data[0].temperature < self.idealBank[self.loaderType.data[0].plantType]!.temperature) {
                        self.notifyTemperature()
                    }
                }
            }
        }
    }
    
    func notifyWater() {
        let content = UNMutableNotificationContent()
        content.title = "Please Water Your Plant"
        content.body = "Your Plant's Moisture is Below its Ideal Condition."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "Water", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
    
    func notifyTemperature() {
        let content = UNMutableNotificationContent()
        content.title = "Please Move Your Plant to a Warmer Location."
        content.body = "Your Plant's Temperature is Below its Ideal Condition."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "Temp", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
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

struct TypeData: Codable {
    public var plantType: String
    
    enum CodingKeys: String, CodingKey {
           case plantType = "plantType"
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
