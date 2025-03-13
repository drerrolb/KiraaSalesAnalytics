import Foundation
import Metal

// MARK: - Decoding Functions

/// Decodes only the year flags from a 64-bit binary string.
/// (Indices 0–4 and 32–36)
func decodeYear(_ binary: String) -> [String: Bool] {
    let chars = Array(binary)
    guard chars.count >= 64 else {
        fatalError("Binary string is too short. Expected at least 64 characters, got \(chars.count).")
    }
    
    var yearFlags = [String: Bool]()
    // Calendar Year Flags (indices 0..4)
    yearFlags[YearType.thisCalendarYear.rawValue] = (chars[0] == "1")
    yearFlags[YearType.lastCalendarYear.rawValue] = (chars[1] == "1")
    yearFlags[YearType.nextCalendarYear.rawValue] = (chars[2] == "1")
    yearFlags[YearType.prior2CalendarYear.rawValue] = (chars[3] == "1")
    yearFlags[YearType.subseq2CalendarYear.rawValue] = (chars[4] == "1")
    // Financial Year Flags (indices 32..36)
    yearFlags[YearType.thisFinancialYear.rawValue] = (chars[32] == "1")
    yearFlags[YearType.lastFinancialYear.rawValue] = (chars[33] == "1")
    yearFlags[YearType.nextFinancialYear.rawValue] = (chars[34] == "1")
    yearFlags[YearType.prior2FinancialYear.rawValue] = (chars[35] == "1")
    yearFlags[YearType.subseq2FinancialYear.rawValue] = (chars[36] == "1")
    
    return yearFlags
}

/// Decodes all time period flags (everything except year flags) from a 64-bit binary string.
func decodeTimeperiod(_ binary: String) -> [String: Bool] {
    let chars = Array(binary)
    guard chars.count >= 64 else {
        fatalError("Binary string is too short. Expected at least 64 characters, got \(chars.count).")
    }
    
    var flags = [String: Bool]()
    
    // Calendar Months (indices 5..16)
    let calMonthLabels = [
        "januarymonth", "februarymonth", "marchmonth", "aprilmonth", "maymonth", "junemonth",
        "julymonth", "augustmonth", "septembermonth", "octobermonth", "novembermonth", "decembermonth"
    ]
    for i in 0..<12 { flags[calMonthLabels[i]] = (chars[5 + i] == "1") }
    
    // Calendar YTD (indices 17..28)
    let calYTDLabels = [
        "januaryytd", "februaryytd", "marchytd", "aprilytd", "mayytd", "juneytd",
        "julyytd", "augustytd", "septemberytd", "octoberytd", "novemberytd", "decemberytd"
    ]
    for i in 0..<12 { flags[calYTDLabels[i]] = (chars[17 + i] == "1") }
    
    // Calendar Rolling (indices 29..31)
    flags["rollingcalendarR03"] = (chars[29] == "1")
    flags["rollingcalendarR06"] = (chars[30] == "1")
    flags["rollingcalendarR12"] = (chars[31] == "1")
    
    // Financial Period (indices 37..48)
    let finPeriodLabels = [
        "p01period", "p02period", "p03period", "p04period", "p05period", "p06period",
        "p07period", "p08period", "p09period", "p10period", "p11period", "p12period"
    ]
    for i in 0..<12 { flags[finPeriodLabels[i]] = (chars[37 + i] == "1") }
    
    // Financial YTD (indices 49..60)
    let finYTDLabels = [
        "p01ytd", "p02ytd", "p03ytd", "p04ytd", "p05ytd", "p06ytd",
        "p07ytd", "p08ytd", "p09ytd", "p10ytd", "p11ytd", "p12ytd"
    ]
    for i in 0..<12 { flags[finYTDLabels[i]] = (chars[49 + i] == "1") }
    
    // Financial Rolling (indices 61..63)
    flags["rollingfinancialR03"] = (chars[61] == "1")
    flags["rollingfinancialR06"] = (chars[62] == "1")
    flags["rollingfinancialR12"] = (chars[63] == "1")
    
    return flags
}


// MARK: - Metal Processing Helper

/// Runs the Metal compute shader on the given date codes and decodes the GPU-generated flag strings.
/// - Parameters:
///   - dateCodes: Array of dates in YYYYMMDD format.
///   - processDate: The process date used by the shader.
///   - financialOffset: Financial offset for date processing.
///   - decode: A closure to decode a 65-character C-string into flag dictionary.
/// - Returns: Array of tuples containing the date code and an array of flag names that were set.
///
///
///
///
///

private func processDateCodesWithMetal(
    dateCodes: [UInt32],
    processDate: UInt32,
    financialOffset: UInt32,
    decode: (String) -> [String: Bool]
) -> [(UInt32, [String])] {
    
    // 1. Metal setup: device, command queue, and library
    guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Metal is not supported on this device") }
    guard let commandQueue = device.makeCommandQueue() else { fatalError("Failed to create Metal command queue") }
    guard let metalLibPath = Bundle.module.path(forResource: "default", ofType: "metallib") else {
        fatalError("Could not find default.metallib in Bundle.module")
    }
    
    let library: MTLLibrary
    do {
        library = try device.makeLibrary(filepath: metalLibPath)
    } catch {
        fatalError("Failed to create Metal library from default.metallib: \(error)")
    }
    
    guard let function = library.makeFunction(name: "processDateCode") else {
        fatalError("Failed to find Metal function 'processDateCode'")
    }
    
    let pipelineState: MTLComputePipelineState
    do {
        pipelineState = try device.makeComputePipelineState(function: function)
    } catch {
        fatalError("Failed to create compute pipeline state: \(error)")
    }
    
    // 2. Create input buffers
    let dateBuffer = device.makeBuffer(
        bytes: dateCodes,
        length: dateCodes.count * MemoryLayout<UInt32>.size,
        options: []
    )!
    
    let processDateBuffer = device.makeBuffer(
        bytes: [processDate],
        length: MemoryLayout<UInt32>.size,
        options: []
    )!
    
    let financialOffsetBuffer = device.makeBuffer(
        bytes: [financialOffset],
        length: MemoryLayout<UInt32>.size,
        options: []
    )!
    
    // 3. Buffers for GPU‐calculated “processing dates”
    var calendarProcessingDate: UInt32 = 0
    var financialProcessingDate: UInt32 = 0
    
    let calendarProcessingDateBuffer = device.makeBuffer(
        bytes: &calendarProcessingDate,
        length: MemoryLayout<UInt32>.size,
        options: .storageModeShared
    )!
    
    let financialProcessingDateBuffer = device.makeBuffer(
        bytes: &financialProcessingDate,
        length: MemoryLayout<UInt32>.size,
        options: .storageModeShared
    )!
    
    // 4. Create the output buffer (65 CChars per date)
    let numCharsPerDate = 65
    let outputSize = dateCodes.count * numCharsPerDate * MemoryLayout<CChar>.size
    let outputBuffer = device.makeBuffer(length: outputSize, options: .storageModeShared)!
    
    // 5. Set up and dispatch the compute kernel
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
    
    commandEncoder.setComputePipelineState(pipelineState)
    commandEncoder.setBuffer(dateBuffer, offset: 0, index: 0)
    commandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
    commandEncoder.setBuffer(processDateBuffer, offset: 0, index: 2)
    commandEncoder.setBuffer(financialOffsetBuffer, offset: 0, index: 3)
    commandEncoder.setBuffer(calendarProcessingDateBuffer, offset: 0, index: 4)
    commandEncoder.setBuffer(financialProcessingDateBuffer, offset: 0, index: 5)
    
    let threads = MTLSize(width: dateCodes.count, height: 1, depth: 1)
    let threadsPerGroup = MTLSize(width: 1, height: 1, depth: 1)
    commandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerGroup)
    
    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
    // 6. (Optional) Decode output flag strings for debugging
    let outputPointer = outputBuffer.contents().bindMemory(to: CChar.self, capacity: outputSize)
    let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    for i in 0..<min(10, dateCodes.count) {
        let offset = i * numCharsPerDate
        let binaryString = String(cString: outputPointer.advanced(by: offset))
        
        let processYear  = processDate / 10000
        let processMonth = (processDate / 100) % 100
        let processDay   = processDate % 100
        let formattedProcessDate = "\(monthNames[Int(processMonth) - 1]) \(processDay), \(processYear)"
        
        _ = decode(binaryString)
        // Optional: print or log formattedProcessDate and decoded flags
    }
    
    // 7. Determine process month keys and add current keys based on decoded flags.
    let processMonth = (processDate / 100) % 100
    // Calendar month keys from indices 5..16 in decodeTimeperiod:
    let calendarMonthKeys = [
        "januarymonth", "februarymonth", "marchmonth", "aprilmonth", "maymonth", "junemonth",
        "julymonth", "augustmonth", "septembermonth", "octobermonth", "novembermonth", "decembermonth"
    ]
    let currentCalendarMonthKey = calendarMonthKeys[Int(processMonth) - 1]
    
    // Calendar YTD keys from indices 17..28:
    let calendarYTDKeys = [
        "januaryytd", "februaryytd", "marchytd", "aprilytd", "mayytd", "juneytd",
        "julyytd", "augustytd", "septemberytd", "octoberytd", "novemberytd", "decemberytd"
    ]
    let currentCalendarYTDKey = calendarYTDKeys[Int(processMonth) - 1]
    
    // Financial period keys from indices 37..48:
    let financialPeriodKeys = [
        "p01period", "p02period", "p03period", "p04period", "p05period", "p06period",
        "p07period", "p08period", "p09period", "p10period", "p11period", "p12period"
    ]
    let currentFinancialPeriodKey = financialPeriodKeys[Int(processMonth) - 1]
    
    var validMembersForDates = [(UInt32, [String])]()
    
    
    for i in 0..<dateCodes.count {
        let offset = i * numCharsPerDate
        let binaryString = String(cString: outputPointer.advanced(by: offset))
        let decodedFlags = decode(binaryString)
        var validMembers = decodedFlags.filter { $0.value }.map { $0.key }
        
        // Add new current keys based on the process month:
        if let isCurrentCalMonth = decodedFlags[currentCalendarMonthKey], isCurrentCalMonth {
            validMembers.append("currentcalendarmonth")
        }
        
        // For currentcalendarytd, check all YTD flags from January up through the process month.
        var isCurrentCalYTD = false
        for m in 0..<Int(processMonth) {
            let key = calendarYTDKeys[m]
            if let flag = decodedFlags[key], flag {
                isCurrentCalYTD = true
                break
            }
        }
        if isCurrentCalYTD {
            validMembers.append("currentcalendarytd")
        }
        
        // For current calendar YTG (year-to-go): if any calendar YTD flags from the current month onward are set.
        var isCurrentCalYTG = false
        for m in Int(processMonth)..<12 {
            let key = calendarYTDKeys[m]
            if let flag = decodedFlags[key], flag {
                isCurrentCalYTG = true
                break
            }
        }
        
        
        // For current financial YTD, check all financial YTD flags (p01ytd to p12ytd)
       // from period 1 up through the process month.
       var isCurrentFinYTD = false
       let financialYTDKeys = [
           "p01ytd", "p02ytd", "p03ytd", "p04ytd", "p05ytd", "p06ytd",
           "p07ytd", "p08ytd", "p09ytd", "p10ytd", "p11ytd", "p12ytd"
       ]
       for m in 0..<Int(processMonth) {
           let key = financialYTDKeys[m]
           if let flag = decodedFlags[key], flag {
               isCurrentFinYTD = true
               break
           }
       }
       if isCurrentFinYTD {
           validMembers.append("currentfinancialytd")
       }

        
        
        
        
        if isCurrentCalYTG {
            validMembers.append("currentcalendarytg")
        }
        
        if let isCurrentFin = decodedFlags[currentFinancialPeriodKey], isCurrentFin {
            validMembers.append("currentcalendarfy")
        }
        
        // Check the current financial period flag and add "currentfinancialperiod" if set.
          if let isCurrentFin = decodedFlags[currentFinancialPeriodKey], isCurrentFin {
              validMembers.append("currentfinancialperiod")
          }
    
        
        if !validMembers.isEmpty {
            validMembersForDates.append((dateCodes[i], validMembers))
        }
    }
    
    //print (validMembersForDates)
    return validMembersForDates
}




// MARK: - Public API

/// Processes date codes using Metal and decodes both year and time period flags.
func processTimeperiodWithMetal(dateCodes: [UInt32], processDate: UInt32, financialOffset: UInt32) -> [(UInt32, [String])] {
    return processDateCodesWithMetal(
        dateCodes: dateCodes,
        processDate: processDate,
        financialOffset: financialOffset,
        decode: decodeTimeperiod
    )
}

/// Processes date codes using Metal and decodes only the year flags.
func processYearWithMetal(dateCodes: [UInt32], processDate: UInt32, financialOffset: UInt32) -> [(UInt32, [String])] {
    return processDateCodesWithMetal(
        dateCodes: dateCodes,
        processDate: processDate,
        financialOffset: financialOffset,
        decode: decodeYear
    )
}
