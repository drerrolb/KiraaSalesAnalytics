//
//  HomeContentView.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 20/3/2025.
//

import Foundation
import SwiftUI


// MARK: - HomeContentView with Detailed Instance Selection
struct HomeContentView: View {
    // User Preferences persisted with AppStorage.
    @AppStorage("home_showNotifications") private var showNotifications: Bool = false
    @AppStorage("home_preferredTheme") private var preferredTheme: String = "System"
    @AppStorage("home_preferredInstance") private var preferredInstance: Int = 1
    
    // Themes for the user to choose from.
    private let themes = ["Light", "Dark", "System"]
    
    // Loaded instances from the JSON file.
    @State private var instances: [Instance] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Welcome Section
                Text("Welcome to the Home Screen")
                    .font(.largeTitle)
                    .padding(.top)
                Text("This is the new home screen option.")
                    .foregroundColor(.secondary)
                
                Divider()
                
                // User Preferences Section
                Text("User Preferences")
                    .font(.headline)
                    .padding(.horizontal)
                
                Toggle(isOn: $showNotifications) {
                    Text("Enable Notifications")
                }
                .padding(.horizontal)
                
                Picker("Preferred Theme", selection: $preferredTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Instance Selection Section
                Picker("Preferred Instance", selection: $preferredInstance) {
                    ForEach(instances) { instance in
                        Text(instance.name)
                            .tag(instance.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                
                // Display details for the selected instance.
                if let selectedInstance = instances.first(where: { $0._id == preferredInstance }) {
                    Divider()
                    Text("Selected Instance Details")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    InstanceDetailsView(instance: selectedInstance)
                        .padding(.horizontal)
                } else {
                    Text("No instance selected.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
   
    
}
