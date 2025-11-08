//
//  main.swift
//  obdii_play
//
//  Created by cisstudent on 10/31/25.
//

import Combine
import Foundation
import SwiftOBD2


var cancellables = Set<AnyCancellable>()

// Keep OBDService alive for the lifetime of the tool.
//let obdService = OBDService(connectionType: .demo)
let obdService = OBDService(
    connectionType: .demo,
    host: "localhost",
    port: 35000
)

let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")
print(name ?? "nil")

Task {
    do {
        let obd2Info = try await obdService.startConnection(preferedProtocol: .protocol6, timeout: 10, querySupportedPIDs: true)
    
        print("Connected. VIN info: \(obd2Info.vin ?? "Unknown")")
        
        // Unwrap Optional supportedPIDs explicitly to avoid debug-description warning
        if let supported = obd2Info.supportedPIDs {
            print("Supported PIDS: \(supported)")
        } else {
            print("Supported PIDS: none")
        }

        let troubleCodes = try? await obdService.scanForTroubleCodes()
        if let troubleCodes {
            // Make the dictionary output readable
            if troubleCodes.isEmpty {
                print("Trouble codes: none")
            } else {
                let formatted = troubleCodes.map { ecuid, codes in
                    let list = codes.map { "\($0)" }.joined(separator: ", ")
                    return "\(ecuid): [\(list)]"
                }.joined(separator: " | ")
                print("Trouble codes: \(formatted)")
            }
        } else {
            print("Trouble codes: nil (scan failed or returned no data)")
        }
        
        // Individual stream for RPM
        obdService
            .startContinuousUpdates([.mode1(.controlModuleVoltage)],interval: 1)
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

        

    } catch {
        obdError("Failed to connect/start: \(error)")
    }
}

// Keep the command-line tool running to receive Combine timer events.
RunLoop.main.run()
