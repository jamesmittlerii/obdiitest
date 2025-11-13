//
//  main.swift
//  obdii_play
//
//  Created by cisstudent on 10/31/25.
//

import Combine
import Foundation
import SwiftOBD2
import OSLog

struct LogEntry: Codable, Sendable {
    let timestamp: Date
    let category: String
    let subsystem: String
    let message: String
}

var cancellables = Set<AnyCancellable>()

// Keep OBDService alive for the lifetime of the tool.
//let obdService = OBDService(connectionType: .demo)
let obdService = OBDService(
    connectionType: .demo,
    host: "localhost",
    port: 35000
)

func collectLogs(since: TimeInterval = -300) async throws -> Data {
    let subsystem = "com.swiftobd2.library"
    // 1. Open the log store for the current process
    let logStore = try OSLogStore(scope: .currentProcessIdentifier)

    // 2. Define a time range (e.g., last minute)
    let oneMinAgo = logStore.position(date: Date().addingTimeInterval(since))

    // 3. Fetch all entries since that position
    let allEntries = try logStore.getEntries(at: oneMinAgo)

    // 4. Narrow to OSLogEntryLog first to ease type-checking
    let logEntries = allEntries.compactMap { $0 as? OSLogEntryLog }

    // 5. Filter by subsystem and category
    let filtered = logEntries.filter {
        $0.subsystem == subsystem && ($0.category == "Connection" || $0.category == "Communication")
    }

    // 6. Map to your LogEntry structure
    let appLogs: [LogEntry] = filtered.map { entry in
        LogEntry(
            timestamp: entry.date,
            category: entry.category,
            subsystem: entry.subsystem,
            message: entry.composedMessage // Respects privacy masks
        )
    }

    let jsonData = try JSONEncoder().encode(appLogs)
    return jsonData
}

Task {
    do {
        
        let obd2Info = try await obdService.startConnection(preferedProtocol: .protocol6, timeout: 20, querySupportedPIDs: true)
    
        obdInfo("Connected. VIN info: \(obd2Info.vin ?? "Unknown")")
        
        // Unwrap Optional supportedPIDs explicitly to avoid debug-description warning
        if let supported = obd2Info.supportedPIDs {
            obdInfo("Supported PIDS: \(supported)")
        } else {
            obdWarning("Supported PIDS: none")
        }

        let troubleCodes = try? await obdService.scanForTroubleCodes()
        if let troubleCodes {
            // Make the dictionary output readable
            if troubleCodes.isEmpty {
                obdInfo("Trouble codes: none")
            } else {
                let formatted = troubleCodes.map { ecuid, codes in
                    let list = codes.map { "\($0)" }.joined(separator: ", ")
                    return "\(ecuid): [\(list)]"
                }.joined(separator: " | ")
                obdInfo("Trouble codes: \(formatted)")
            }
        } else {
            obdInfo("Trouble codes: nil (scan failed or returned no data)")
        }
        
        
        let response = try await obdService.requestPID(.mode1(.status), unit: MeasurementUnit.metric)
        print(response)
        
        print(try await obdService.requestPID(.mode1(.maf), unit: MeasurementUnit.imperial))
      
        
        //print(try await obdService.requestPID(.mode1(.O2Sensor7WRCurrent), unit: MeasurementUnit.metric))
       // print(try await obdService.requestPID(.mode1(.fuelRailPressureAbs), unit: MeasurementUnit.metric))
       // print(try await obdService.requestPID(.mode1(.fuelRailPressureDirect), unit: MeasurementUnit.imperial))
       // print(try await obdService.requestPID(.mode1(.fuelRailPressureVac), unit: MeasurementUnit.metric))
        
        
      //  print(try await obdService.requestPID(.GMmode22(.ACHighPressure), unit: MeasurementUnit.metric))
      //  print(try await obdService.requestPID(.GMmode22(.engineOilPressure), unit: MeasurementUnit.metric))
       // print(try await obdService.requestPID(.mode1(.engineOilTemp), unit: MeasurementUnit.metric))
       // print(try await obdService.requestPID(.GMmode22(.engineOilTemp), unit: MeasurementUnit.metric))
       // print(try await obdService.requestPID(.GMmode22(.transFluidTemp), unit: MeasurementUnit.metric))
        
        
        //print(try await obdService.sendCommand("221154"))
        //print(try await obdService.sendCommand("221470"))
        //print(try await obdService.sendCommand("221940"))
        //print(try await obdService.sendCommand("221144"))
       // print(try await obdService.sendCommand("221161"))
        //print(try await obdService.sendCommand("22162B"))
        //print(try await obdService.sendCommand("221310"))
        //print(try await obdService.sendCommand("2201"))
        
        /*
        print(try await obdService.requestPID(.mode1(.rpm), unit: MeasurementUnit.metric))
        
        
        let response2 = try await obdService.requestPID(.mode1(.ambientAirTemp), unit: MeasurementUnit.metric)
        print(response2)
       
        let pid = OBDCommand.GMMode22.engineOilPressure
        */
        
        let json = try await collectLogs()
        /*
        // Individual stream for RPM
        obdService
            .startContinuousUpdates([.mode1(.status)],interval: 1)
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
        obdError("Failed to connect/start: \(error)")
    }
}

// Keep the command-line tool running to receive Combine timer events.
RunLoop.main.run()
