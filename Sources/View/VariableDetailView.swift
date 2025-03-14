//
//  VariableDetailView.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 13/3/2025.
//

import Foundation
import SwiftUI

struct VariableDetailView: View {
    let variableKey: String
    let attributes: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details for \(variableKey)")
                .font(.largeTitle)
                .padding(.top)
            
            List {
                ForEach(attributes.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(attributes[key] ?? "")
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Variable Details")
    }
}
