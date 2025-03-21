//
//  VariablesBrowserContentView.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 15/3/2025.
//

import Foundation
import SwiftUI

// MARK: - VariablesBrowserContentView (Modal)
struct VariablesBrowserContentView: View {
    @Environment(\.dismiss) private var dismiss

    // The merged dictionaries from your analytics code.
    let dictionary: [String: [String: String]] = AllAnalyticsDictionaries.allDictionaries

    var body: some View {
        NavigationView {
            List {
                ForEach(dictionary.keys.sorted(), id: \.self) { key in
                    NavigationLink(destination: VariableDetailView(variableKey: key, attributes: dictionary[key] ?? [:])) {
                        Text(key)
                    }
                }
            }
            .navigationTitle("Variables Browser")
            .toolbar {
                // Add a close button to the navigation bar.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}
