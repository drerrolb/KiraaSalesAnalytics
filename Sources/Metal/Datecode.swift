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
    
    // retrieve the binary array
    let chars = Array(binary)
    var flags = [String: Bool]()
    
    // check the buffer is 64
    guard chars.count >= 64 else {
        fatalError("Binary string is too short. Expected at least 64 characters, got \(chars.count).")
    }

    
    // =========================================================================================
    // CALENDAR MONTHS
    // Calendar Months (indices 5..16)
    // =========================================================================================

    let calMonthLabels = [
        "januarymonth", "februarymonth", "marchmonth", "aprilmonth", "maymonth", "junemonth",
        "julymonth", "augustmonth", "septembermonth", "octobermonth", "novembermonth", "decembermonth"
    ]
    
    let calYTDLabels = [
        "januaryytd", "februaryytd", "marchytd", "aprilytd", "mayytd", "juneytd",
        "julyytd", "augustytd", "septemberytd", "octoberytd", "novemberytd", "decemberytd"
    ]
    
    
    // populate the month set
    for i in 0..<12 { flags[calMonthLabels[i]] = (chars[5 + i] == "1") }
    
    // populate the year-to-date set so that if the current month is true,
    // then all subsequent months will also be true
    for i in 0..<12 {
        if flags[calMonthLabels[i]] == true {
            for j in i..<12 {
                flags[calYTDLabels[j]] = true
                //print("\(calYTDLabels[j]) set to true")
            }
        }
    }
    
    // =========================================================================================
    // ROLLING PERIODS CURRENTLY NOT USED
    // =========================================================================================

    // Calendar YTD (indices 17..28)

    //for i in 0..<12 { flags[calYTDLabels[i]] = (chars[17 + i] == "1") }
    
    // Calendar Rolling (indices 29..31)
    flags["rollingcalendarR03"] = (chars[29] == "1")
    flags["rollingcalendarR06"] = (chars[30] == "1")
    flags["rollingcalendarR12"] = (chars[31] == "1")
    
    
    // =========================================================================================
    // FINANCIAL PERIODS
    // Financial Period (indices 37..48)
    // Financial YTD (indices 49..60)
    // =========================================================================================

    let finPeriodLabels = [
        "p01", "p02", "p03", "p04", "p05", "p06",
        "p07", "p08", "p09", "p10", "p11", "p12"
    ]
    
    let finYTDLabels = [
        "p01ytd", "p02ytd", "p03ytd", "p04ytd", "p05ytd", "p06ytd",
        "p07ytd", "p08ytd", "p09ytd", "p10ytd", "p11ytd", "p12ytd"
    ]
    
    // populate the period set
    for i in 0..<12 { flags[finPeriodLabels[i]] = (chars[37 + i] == "1") }
    
    // populate the period fytd set so that if a period is true,
    // then that period and all subsequent periods will also be true
    for i in 0..<12 {
        if flags[finPeriodLabels[i]] == true {
            for j in i..<12 {
                flags[finYTDLabels[j]] = true
                //print("\(finYTDLabels[j]) set to true")
            }
        }
    }

    // =========================================================================================
    // ROLLING PERIODS CURRENTLY NOT USED
    // =========================================================================================


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
    
    // =========================================================================================
    // INIIALIZE METAL LIBRARY
    // =========================================================================================

    let metalLibURL = URL(fileURLWithPath: metalLibPath)

    let library: MTLLibrary
    
    do      { library = try device.makeLibrary(URL: metalLibURL) }
    catch   { fatalError("Failed to create Metal library from default.metallib: \(error)") }
    
    // =========================================================================================
    // process date code
    // =========================================================================================
    
    guard let function = library.makeFunction(name: "processDateCode") else {
        fatalError("Failed to find Metal function 'processDateCode'")
    }
    
    let pipelineState: MTLComputePipelineState
    
    do      { pipelineState = try device.makeComputePipelineState(function: function) }
    catch   { fatalError("Failed to create compute pipeline state: \(error)") }
    
    // =========================================================================================
    //  Input Buffers
    //  1. Source  Date Buffer
    //  2. Process Date Buffer
    //  3. Offset  Buffer
    //  4. Calendar Processing Buffer
    //  5. Financial Processing Buffer
    // =========================================================================================
    
    // input buffers for date
    let dateBuffer = device.makeBuffer(
        bytes: dateCodes,
        length: dateCodes.count * MemoryLayout<UInt32>.size,
        options: []
    )!
    
    // process buffers for date
    let processDateBuffer = device.makeBuffer(
        bytes: [processDate],
        length: MemoryLayout<UInt32>.size,
        options: []
    )!
    
    // financial offset buffer
    let financialOffsetBuffer = device.makeBuffer(
        bytes: [financialOffset],
        length: MemoryLayout<UInt32>.size,
        options: []
    )!
    
    // 3. Buffers for GPU‐calculated “processing dates”
    var calendarProcessingDate: UInt32 = 0

    let calendarProcessingDateBuffer = device.makeBuffer(
        bytes: &calendarProcessingDate,
        length: MemoryLayout<UInt32>.size,
        options: .storageModeShared
    )!
    
    var financialProcessingDate: UInt32 = 0
    
    let financialProcessingDateBuffer = device.makeBuffer(
        bytes: &financialProcessingDate,
        length: MemoryLayout<UInt32>.size,
        options: .storageModeShared
    )!
    
    // =========================================================================================
    //  Output Buffer
    // =========================================================================================
    
    // 4. Create the output buffer (65 CChars per date)
    let numCharsPerDate = 65
    let outputSize = dateCodes.count * numCharsPerDate * MemoryLayout<CChar>.size
    let outputBuffer = device.makeBuffer(length: outputSize, options: .storageModeShared)!
    
    // =========================================================================================
    //  Command Encoder
    // =========================================================================================
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
    let threads = MTLSize(width: dateCodes.count, height: 1, depth: 1)
    let threadsPerGroup = MTLSize(width: 1, height: 1, depth: 1)
    
    // pipeline
    commandEncoder.setComputePipelineState(pipelineState)

    // buffer
    commandEncoder.setBuffer(dateBuffer, offset: 0, index: 0)
    commandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
    commandEncoder.setBuffer(processDateBuffer, offset: 0, index: 2)
    commandEncoder.setBuffer(financialOffsetBuffer, offset: 0, index: 3)
    commandEncoder.setBuffer(calendarProcessingDateBuffer, offset: 0, index: 4)
    commandEncoder.setBuffer(financialProcessingDateBuffer, offset: 0, index: 5)
    
    // threads
    commandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerGroup)
    
    // end encoding
    commandEncoder.endEncoding()
    
    // execute
    commandBuffer.commit()
    
    // wait
    commandBuffer.waitUntilCompleted()
    
    // =========================================================================================
    // Decoding Strings
    // =========================================================================================
    
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
        
        //print ("\(i): \(binaryString)")

    }
    
    // =========================================================================================
    // CURRENT PERIOD DETERMINATIONS
    // =========================================================================================
    
    // strip out the months
    let processMonth =  (processDate / 100) % 100
    let processPeriod = ((processMonth - 1) + financialOffset) % 12 + 1

    // look up the current Calendar Month Key
    let calendarMonthKeys = [
        "januarymonth", "februarymonth", "marchmonth",
        "aprilmonth", "maymonth", "junemonth",
        "julymonth", "augustmonth", "septembermonth",
        "octobermonth", "novembermonth", "decembermonth"
    ]
    
    let currentCalendarMonthKey = calendarMonthKeys[Int(processMonth) - 1]
    
    //print ("Current Calendar Month key is \(currentCalendarMonthKey)")
    
    // Calendar YTD keys from indices 17..28:
    let calendarYTDKeys = [
        "januaryytd", "februaryytd", "marchytd",
        "aprilytd", "mayytd", "juneytd",
        "julyytd", "augustytd", "septemberytd", 
        "octoberytd", "novemberytd", "decemberytd"
    ]
    
    let currentCalendarYTDKey = calendarYTDKeys[Int(processMonth) - 1]
    
    //print ("Current Calendar YTD key is \(currentCalendarYTDKey)")
    
    // Financial period keys from indices 37..48:
    let financialPeriodKeys = [
            "p01", "p02", "p03", "p04", "p05", "p06",
            "p07", "p08", "p09", "p10", "p11", "p12"
    ]
    
    let currentFinancialPeriodKey = financialPeriodKeys[Int(processPeriod) - 1]
    
    //print ("Current Financial Period is key is \(currentFinancialPeriodKey)")
    
    // Financial FYTD
    
    let financialYTDKeys = [
        "p01ytd", "p02ytd", "p03ytd", "p04ytd", "p05ytd", "p06ytd",
        "p07ytd", "p08ytd", "p09ytd", "p10ytd", "p11ytd", "p12ytd"
    ]
    
    let currentFinancialYTDKey = financialYTDKeys[Int(processPeriod) - 1]
    
    //print ("Current Financial Period is key is \(currentFinancialYTDKey)")
    
    
    var validMembersForDates = [(UInt32, [String])]()
    
    // =========================================================================================
    // CURRENT PERIOD DETERMINATIONS
    // =========================================================================================
    
    for i in 0..<dateCodes.count {
        
        // who are we working with
        //print("Processing date code \(dateCodes[i])")
        
        let offset = i * numCharsPerDate
        let binaryString = String(cString: outputPointer.advanced(by: offset))
        let decodedFlags = decode(binaryString)
        var validMembers = decodedFlags.filter { $0.value }.map { $0.key }
        
        // =========================================================================================
        // CALENDAR MONTH
        // CALENDAR YTD
        // =========================================================================================
        
        
        if let isCurrentCalMonth = decodedFlags[currentCalendarMonthKey], isCurrentCalMonth {
            validMembers.append("currentcalendarmonth")
            //print ("Appended Current Calendar Month")
        }
        
        
        if let isCurrentCalYTD = decodedFlags[currentCalendarYTDKey], isCurrentCalYTD {
            validMembers.append("currentcalendarytd")
            //print ("Appended Current Calendar YTD")
        }
        
      
        // =========================================================================================
        // FISCAL PERIOD
        // FISCAL FYTD
        // =========================================================================================
        
        if let isCurrentFinPeriod = decodedFlags[currentFinancialPeriodKey], isCurrentFinPeriod {
            validMembers.append("currentfinancialperiod")
            //print ("Appended Current Financial Period")
        }
        
        // if the current YTD exist in the list of decoded flags

        
        if let isCurrentFinYTD = decodedFlags[currentFinancialYTDKey], isCurrentFinYTD {
            validMembers.append("currentfinancialytd")
            //print ("Appended Current Financial YTD")
        }
        
        // =========================================================================================
        // CF
        // =========================================================================================
    
        if !validMembers.isEmpty {
            validMembersForDates.append((dateCodes[i], validMembers))
            //print("Date code: \(dateCodes[i]), Valid Members: \(validMembers)")
        }
        
        //print ("\n")
        
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
