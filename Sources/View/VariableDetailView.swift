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
        VStack(alignment: .leading) {
            Text(variableKey)
                .font(.title)
                .bold()
                .padding(.top, 10)
            
            Divider()
            
            Form {
                // Show each attribute in a row: attributeKey → attributeValue
                ForEach(attributes.keys.sorted(), id: \.self) { attrKey in
                    HStack {
                        Text(attrKey)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(attributes[attrKey] ?? "")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 5)
            
            Spacer()
        }
        .padding([.leading, .trailing], 20)
        .navigationTitle(variableKey)
    }
}
