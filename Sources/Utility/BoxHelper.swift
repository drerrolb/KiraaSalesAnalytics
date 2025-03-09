//
//  BoxtedText.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 21/2/2025.
//


import Foundation

// Helper to center text within a fixed width.
public func centerText(_ text: String, width: Int) -> String {
    let padding = max(0, width - text.count)
    let leftPadding = padding / 2
    let rightPadding = padding - leftPadding
    return String(repeating: " ", count: leftPadding) + text + String(repeating: " ", count: rightPadding)
}

// Helper to wrap text into lines not exceeding a given width.
public func wrapText(_ text: String, width: Int) -> [String] {
    var lines: [String] = []
    var currentLine = ""
    let words = text.split(separator: " ").map(String.init)
    for word in words {
        if currentLine.isEmpty {
            currentLine = word
        } else if currentLine.count + 1 + word.count <= width {
            currentLine += " " + word
        } else {
            lines.append(currentLine)
            currentLine = word
        }
    }
    if !currentLine.isEmpty {
        lines.append(currentLine)
    }
    return lines
}

// Function that prints a visually appealing boxed final message.
public func printFinalBox(executionMessage: String, executionTime: String, executionStatus: String) {
    let boxWidth = 99
    let horizontalBorder = String(repeating: "═", count: boxWidth - 2)
    let topBorder = "╔" + horizontalBorder + "╗"
    let bottomBorder = "╚" + horizontalBorder + "╝"
    let emptyLine = "║" + String(repeating: " ", count: boxWidth - 2) + "║"
    
    // Build the box
    print(topBorder)
    print(emptyLine)
    
    // Centered complete message
    let completeLine = "|" + centerText("*** COMPLETE ***", width: boxWidth - 2) + "║"
    print(completeLine)
    print(emptyLine)
    
    // Wrap and print the execution message.
    let wrappedMessage = wrapText("Execution Message : \(executionMessage)", width: boxWidth - 4)
    for line in wrappedMessage {
        let paddedLine = line.padding(toLength: boxWidth - 4, withPad: " ", startingAt: 0)
        print("║  \(paddedLine)  ║")
    }
    
    // Execution time line.
    let timeLine = "Execution Time    : \(executionTime)"
    print("║  " + timeLine.padding(toLength: boxWidth - 4, withPad: " ", startingAt: 0) + "  ║")
    
    // Execution status line.
    let statusLine = "Execution Status  : \(executionStatus)"
    print("║  " + statusLine.padding(toLength: boxWidth - 4, withPad: " ", startingAt: 0) + "  ║")
    
    print(emptyLine)
    print(bottomBorder)
}
