//
//  main.swift
//  obdii_play
//
//  Created by cisstudent on 10/31/25.
//

import Combine
import Foundation
import SwiftOBD2

print("Hello, World!")

var cancellables = Set<AnyCancellable>()

// Keep OBDService alive for the lifetime of the tool.
//let obdService = OBDService(connectionType: .demo)
let obdService = OBDService(
    connectionType: .wifi,
    host: "localhost",
    port: 35000
)

Task {
    do {
        let obd2Info = try await obdService.startConnection(preferedProtocol: .protocol7)
        print("Connected. VIN info: \(obd2Info.vin ?? "Unknown")")

        let troubleCodes = try? await obdService.scanForTroubleCodes()
        if let troubleCodes {
            print("Trouble codes: \(troubleCodes)")
        } else {
            print("Trouble codes: nil (scan failed or returned no data)")
        }
        
        /*
        // Individual stream for RPM
        obdService
            .startContinuousUpdates([.mode1(.engineOilTemp),.mode1(.speed)])
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("updates failed: \(error)")
                    }
                },
                receiveValue: { measurements in
                //let temp = measurements[.mode1(.fuelPressure)]?.value ?? 0
                    print(measurements)
                }
            )
            .store(in: &cancellables)

        */

    } catch {
        print("Failed to connect/start: \(error)")
    }
}

// Keep the command-line tool running to receive Combine timer events.
RunLoop.main.run()
