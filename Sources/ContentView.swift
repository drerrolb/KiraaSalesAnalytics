import SwiftUI
import AppKit

struct ContentView: View {
    @State private var statusMessage = "Ready"
    @State private var showViewController = false
    @State private var showPerformanceCharts = true
    
    /// Controls whether the Variables Browser sheet is open.
    @State private var showVariablesSheet = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 1) A gradient background
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.gray]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            // 2) Main content
            VStack(spacing: 20) {
                Text("Kiraa Sales Analytics")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(statusMessage)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 10)
                
                HStack(spacing: 20) {
                    Button("Run Integration") {
                        Task {
                            await runIntegration()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(showViewController ? "Hide View" : "Show View") {
                        showViewController.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(showPerformanceCharts ? "Hide Charts" : "Show Charts") {
                        showPerformanceCharts.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // 3) Shows the new Variables Browser in a sheet
                    Button("Show Variables") {
                        showVariablesSheet.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(minWidth: 500, minHeight: 400)
            
            // 4) Performance charts in top-right corner
            if showPerformanceCharts {
                GeometryReader { geometry in
                    PerformanceChartsView()
                        .frame(width: geometry.size.width * 0.15,
                               height: geometry.size.height * 0.15)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
        // 5) Existing sheet for the ViewController
        .sheet(isPresented: $showViewController) {
            ViewControllerWrapper(isPresented: $showViewController)
                .frame(minWidth: 800, minHeight: 600)
        }
        
        // 6) New sheet for the Variables Browser (two-column layout)
        .sheet(isPresented: $showVariablesSheet) {
            VariablesBrowserView(isPresented: $showVariablesSheet)
                .frame(minWidth: 800, minHeight: 600)
        }
    }
    
    // MARK: - Integration Logic
    func runIntegration() async {
        statusMessage = "Running integration..."
        
        // Default the source file path
        let sourceFilePath: String = {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                return documentsDirectory.appendingPathComponent("source-sales.csv").path
            } else {
                return "/Users/e2mq173/Projects/dataframes/source-sales.csv"
            }
        }()
        
        // For Ballantyne it's 6; here we force an offset value of 0.
        let offsetValue = 0
        
        // Process integration for each month of 2024 & 2025
        for year in 2024...2025 {
            for month in 1...12 {
                let formattedMonth = String(format: "%02d", month)
                let strProcessDate = "\(year)\(formattedMonth)"
                let fileURL = URL(fileURLWithPath: sourceFilePath)
                
                await SA01Integration.run(
                    fileURL: fileURL,
                    strProcessDate: strProcessDate,
                    fiscalOffset: offsetValue
                )
            }
        }   
        
        statusMessage = "Integration completed."
    }
}
