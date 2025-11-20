#!/usr/bin/env swift

import Foundation

// Import the SwiftOBD2 module path
import SwiftOBD2

let myCommand = OBDCommand.GMmode22(.engineOilPressure)

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

do {
    let jsonData = try encoder.encode(myCommand)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("Serialized OBDCommand.GMmode22(.engineOilPressure):")
        print(jsonString)
    }
} catch {
    print("Error encoding: \(error)")
}
