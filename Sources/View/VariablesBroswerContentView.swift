import SwiftUI

struct VariablesBrowserView: View {
    /// Bound to a Bool in the parent, so we can dismiss ourselves.
    @Binding var isPresented: Bool
    
    /// The merged dictionaries from your analytics code.
    let dictionary: [String: [String: String]] = AllAnalyticsDictionaries.allDictionaries
    
    /// Track which key is selected in the sidebar.
    @State private var selectedKey: String?
    
    var body: some View {
        NavigationView {
            // Sidebar list of keys
            List(selection: $selectedKey) {
                ForEach(dictionary.keys.sorted(), id: \.self) { key in
                    Text(key)
                        .tag(key as String?)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 250) // give the sidebar a minimum width
            .navigationTitle("Variables")
            
            // Detail: if selectedKey is known, show attributes; else a placeholder
            if let key = selectedKey, let attributes = dictionary[key] {
                VariableDetailView(variableKey: key, attributes: attributes)
            } else {
                Text("Select a variable")
                    .foregroundColor(.secondary)
                    .navigationTitle("Details")
            }
        }
        
        .frame(minWidth: 800, minHeight: 600) // overall window size
    }
}
