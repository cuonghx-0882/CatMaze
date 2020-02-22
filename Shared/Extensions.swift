//
//  Extensions.swift
//  Cat Maze
//
//  Created by Matthijs on 19-06-14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation

extension Dictionary {
    // Loads a JSON file from the app bundle into a new dictionary
    static func loadJSONFromBundle(_ filename: String) -> Dictionary<String, AnyObject>? {
        if let path = Bundle.main.url(forResource: filename, withExtension: "json"),
            let data = try? Data(contentsOf: path, options: Data.ReadingOptions.dataReadingMapped) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, AnyObject>
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("Could not find level file: \(filename)")
            return nil
        }
        return nil
    }
}
