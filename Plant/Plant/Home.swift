//
//  Home.swift
//  Plant
//
//  Created by Michael Park on 4/22/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI
import UserNotifications

struct Home: View {

    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()    // Start timer

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
    
    @ObservedObject var loader = DataLoader()       // Fetch sensor data
    @ObservedObject var loaderImage = ImageLoader()     // Fetch image data
    @ObservedObject var loaderType = TypeLoader()       // Fetch Plant type (ML output)
    
    @State var plantImage:UIImage?
    
    @State var count = 0
    @State var plantName = "Unavailable"
    @State var waterToken = false
    @State var heatToken = false
    let defaultHealth = "Your Plant's Conditions are Ideal"
    
    // Initialize ideal plant types
    let idealBasil = IdealPlant(moisture: 50.0, temperature: 15.56, humidity: 50.0)
    
    let idealJade = IdealPlant(moisture: 5.0, temperature: 4.44, humidity: 50.0)
    
    let idealCactus = IdealPlant(moisture: 5.0, temperature: 18.33, humidity: 50.0)
    
    var idealBank = [String:IdealPlant]()
    
    let gradientColors = Gradient(colors: [.green, .blue])
    
    init(){
        // Create top bar
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.753, green: 0.753, blue: 0.753, alpha: 1.0)
        // Create dictionary of ideal values
        idealBank = ["Basil":idealBasil, "Jade Plant":idealJade, "Cactus":idealCactus]
        // Load image
        plantImage = loaderImage.image
    }
        
    var body: some View {
        
        NavigationView{
            ZStack {
                RadialGradient(gradient: gradientColors, center: .center, startRadius: 2, endRadius: 650)
                HStack(alignment: .center){     // Displays Plant Type (ML Output)
                    if (loaderType.data.count != 0) {
                        PlantData(image: Image(uiImage: loaderImage.image), plantName: self.loaderType.data[0].plantType)
                            .offset(x: CGFloat(0), y: CGFloat(-120))
                    } else {
                        PlantData(image: Image(uiImage: loaderImage.image), plantName: "Press Pi Button to ID")
                            .offset(x: CGFloat(0), y: CGFloat(-120))
                    }
                }
                HStack(alignment: .center) {    // Displays Ideal Values of the Plant Type
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
                VStack {    // Displays message box (Informs if plant is healthy or needs attention
                    if (self.waterToken == true && self.heatToken == true) {
                        Text("Water Your Plants and Move to a Warmer Location") // If plant is too cold and needs water
                            .fontWeight(.bold)
                        .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.red, lineWidth: 10)
                        )
                        .position(x: 190, y: 340)
                    } else if (self.waterToken == true) {
                        Text("Please Water Your Plants")    // If plant needs water
                            .fontWeight(.bold)
                        .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.red, lineWidth: 10)
                        )
                        .position(x: 190, y: 340)
                    } else if (self.heatToken == true) {
                        Text("Please Move Your Plants to a Warmer Location")    // If plant is too cold
                            .fontWeight(.bold)
                        .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.red, lineWidth: 10)
                        )
                        .position(x: 190, y: 340)
                    } else{
                        Text(defaultHealth)     // Default, plant is healthy
                            .fontWeight(.bold)
                            
                        .padding()
                            .background(Color.white)
                            .foregroundColor(.green)
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.green, lineWidth: 10)
                        )
                        .position(x: 190, y: 340)

                    }
                }
                VStack {    // Displays current temperature sensor values
                    if (loader.data.count != 0) {
                        Text("Temperature: " + String(format: "%.1f", self.loader.data[0].temperature) + " °C")
                            .font(.title)
                            .position(x: 200, y: 400)
                    } else {
                        Text("Temperature: Unavailable")
                            .font(.title)
                            .position(x: 200, y: 400)
                    }
                }
             
                VStack {    // Displays current moisture sensor values
                    if (loader.data.count != 0) {
                        Text("Moisture Level: " + String(format: "%.1f", self.loader.data[0].moisture) + "%")
                            .font(.title)
                            .position(x: 200, y: 450)
                    } else {
                        Text("Moisture Level: Unavailable")
                            .font(.title)
                            .position(x: 200, y: 450)
                    }
                }
                VStack {    // Displays current humidity values
                    if (loader.data.count != 0) {
                      Text("Humidity: " + String(format: "%.1f", self.loader.data[0].humidity) + "%")
                            .font(.title)
                            .position(x: 200, y: 500)
//                    Text("\(self.count)")
                    } else {
                        Text("Humidity: Unavailable")
                            .font(.title)
                            .position(x: 200, y: 500)
                    }
                }
            }
            .navigationBarTitle("Hello, Planter")
            .onAppear(perform: {    // When navigation bar appears, set up notification center
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge,.sound,.alert]) { (_, _) in
                }
            })
            .onReceive(timer) {time in  // When timer triggers (1 s), refresh sensor values, plant pic, plant id, and parse to launch notifications if necessary
                self.loader.load()
                self.loaderImage.load()
                self.loaderType.load()
                print("\(time)")
                self.count += 1
                if (self.loaderType.data.count != 0) {
                    if (self.loader.data[0].moisture < self.idealBank[self.loaderType.data[0].plantType]!.moisture) {   // Notification check for moisture levels
                        self.notifyWater()
                        self.waterToken = true
                    } else {
                        self.waterToken = false
                    }
                    if (self.loader.data[0].temperature < self.idealBank[self.loaderType.data[0].plantType]!.temperature) { // Notification check for temperature values
                        self.notifyTemperature()
                        self.heatToken = true
                    } else {
                        self.heatToken = false
                    }
                }
            }
        }
    }
    
    // Designs notification message for low moisture
    func notifyWater() {
        let content = UNMutableNotificationContent()
        content.title = "Please Water Your Plant"
        content.body = "Your Plant's Moisture is Below its Ideal Condition."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "Water", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
    
    // Designs notification message for low temperature
    func notifyTemperature() {
        let content = UNMutableNotificationContent()
        content.title = "Please Move Your Plant to a Warmer Location"
        content.body = "Your Plant's Temperature is Below its Ideal Condition."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "Temp", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}

// Struct for holoding sensor data
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

// Struct for holding plant type data
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
