//
//  ImageLoader.swift
//  Plant
//
//  Created by Michael Park on 5/23/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI

public class ImageLoader: ObservableObject {
    @Published var image = UIImage(imageLiteralResourceName: "basil")
    init(){
        load()
    }
    
    func load() {
        
        let url = URL(string: "https://s3-us-west-1.amazonaws.com/plant-sensor-data-storage-plant.ai/image_plant.jpg")!
        let configuration = URLSessionConfiguration.ephemeral //background(withIdentifier: "com.jsonData.refesh)
        let session = URLSession(configuration: configuration)
        session.dataTask(with: url) {(data,response,error) in
            do {
                if let data = try? Data(contentsOf: url) {
                    if let image = UIImage(data:data) {
                        DispatchQueue.main.async {
                            self.image = image
                        }
                    }
                }else {
                    print("No Data")
                }
            }
            
        }.resume()
         
    }
}
