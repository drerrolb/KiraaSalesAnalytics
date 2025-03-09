struct ContentView: View {
    @State private var statusMessage = "Ready"
    @State private var showViewController = false  // State to control the sheet display.
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Kiraa Sales Analytics")
                .font(.largeTitle)
            Text(statusMessage)
                .padding()
            HStack {
                Button("Run Integration") {
                    Task {
                        await runIntegration()
                    }
                }
                // Toggle button to show/hide the ViewController view.
                Button(showViewController ? "Hide View" : "Show View") {
                    showViewController.toggle()
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        // Present the ViewController sheet when showViewController is true.
        .sheet(isPresented: $showViewController) {
            ViewControllerWrapper(isPresented: $showViewController)
                .frame(minWidth: 800, minHeight: 600)
        }
    }
    
    // This async function runs the integration loop.
    func runIntegration() async {
        statusMessage = "Running integration..."
        
        // Default the source file path.
        let sourceFilePath: String = {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                return documentsDirectory.appendingPathComponent("source-sales.csv").path
            } else {
                return "/Users/e2mq173/Projects/dataframes/source-sales.csv"
            }
        }()
        
        // For Ballantyne it's 6; here we force an offset value of 0.
        let offsetValue = 0
        
        // Process integration for each month over the years 2024 to 2025.
        for year in 2024...2025 {
            for month in 1...12 {
                let formattedMonth = String(format: "%02d", month)
                let strProcessDate = "\(year)\(formattedMonth)"
                let fileURL = URL(fileURLWithPath: sourceFilePath)
                
                // Call your asynchronous integration function.
                await SA01Integration.run(fileURL: fileURL,
                                          strProcessDate: strProcessDate,
                                          fiscalOffset: offsetValue)
            }
        }
        
        statusMessage = "Integration completed."
    }
}