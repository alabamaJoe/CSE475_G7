//
//  TypeLoader.swift
//  Plant
//
//  Created by Michael Park on 5/23/20.
//  Copyright © 2020 Michael Park. All rights reserved.
//

import SwiftUI

public class TypeLoader: ObservableObject {
    @Published var data = [TypeData]()
    init(){
        load()
    }
    
    func load() {
        
        let url = URL(string: "https://s3-us-west-1.amazonaws.com/plant-sensor-data-storage-plant.ai/id_plant.json")!
        let configuration = URLSessionConfiguration.ephemeral //background(withIdentifier: "com.jsonData.refesh)
        let session = URLSession(configuration: configuration)
        session.dataTask(with: url) {(data,response,error) in
            do {
                if let d = data {
                    let decodedLists = try JSONDecoder().decode([TypeData].self, from: d)
                    DispatchQueue.main.async {
                        self.data = decodedLists
                        print(decodedLists[0])
                    }
                }else {
                    print("No Data")
                }
            } catch {
                print ("Error")
            }
            
        }.resume()
         
    }
}
