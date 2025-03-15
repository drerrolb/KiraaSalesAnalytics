//
//  ConfigurationView.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 15/3/2025.
//

import Foundation
import SwiftUI

// MARK: - ConfigurationView (Modal)
struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Configuration")
                .font(.title)
            Text("Adjust settings here...")
            Button("Close") {
                dismiss() // Dismisses the modal sheet.
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}
