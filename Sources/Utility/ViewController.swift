import Cocoa
import SpriteKit
import GameplayKit
import Darwin   // Needed for Mach APIs

class ViewController: NSViewController {

    // Outlet for the SKView.
    var skView: SKView!
    
    var cpuGraphView: LineGraphView!
    var memoryGraphView: LineGraphView!
    
    // Reference to the point cloud node.
    var pointCloud: KiraaCloud?
    
    // Timers for updating the scene and usage data.
    var updateTimer: Timer?
    var cloudTimer: Timer?
    
    // Labels to display status information.
    var statusLabel: NSTextField!
    var positionLabel: NSTextField!
    
    // Optional dismiss callback.
    var dismissCallback: (() -> Void)?
    
    override func loadView() {
        // Create a container view to host both the SKView and overlays.
        let containerFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let containerView = NSView(frame: containerFrame)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.darkGray.cgColor
        print("Container view frame: \(containerView.frame)")
        
        // Create the SKView and add it as a subview.
        let skView = SKView(frame: containerView.bounds)
        skView.autoresizingMask = [.width, .height]
        containerView.addSubview(skView)
        print("SKView frame: \(skView.frame)")
        
        self.view = containerView
        self.skView = skView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad: Starting setup.")
        
        // 1) Create the SpriteKit scene programmatically.
        if let skView = self.skView {
            print("Creating scene with size: \(skView.bounds.size)")
            let scene = SKScene(size: skView.bounds.size)
            scene.scaleMode = .resizeFill
            scene.backgroundColor = .black
            
            // Create and configure the point cloud node.
            let cloud = KiraaCloud(size: scene.size)
            cloud.name = "kiraaCloud"
            cloud.progressCenter = CGPoint(x: scene.size.width / 4, y: scene.size.height / 2)
            cloud.position = .zero
            scene.addChild(cloud)
            self.pointCloud = cloud
            print("Added cloud node: progressCenter = \(cloud.progressCenter), position: \(cloud.position)")
            
            skView.presentScene(scene)
            print("Scene presented.")
            
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            // 2) Add a frosted overlay view.
            let frostedWidth: CGFloat = 220
            let frostedHeight: CGFloat = 160
            let margin: CGFloat = 10
            let x = self.view.bounds.width - frostedWidth - margin
            let y = self.view.bounds.height - frostedHeight - margin
            let frostedFrame = NSRect(x: x, y: y, width: frostedWidth, height: frostedHeight)
            print("Frosted view frame: \(frostedFrame)")
            
            let frostedView = NSVisualEffectView(frame: frostedFrame)
            frostedView.material = .hudWindow
            frostedView.blendingMode = .behindWindow
            frostedView.state = .active
            frostedView.wantsLayer = true
            frostedView.layer?.cornerRadius = 15
            frostedView.layer?.masksToBounds = true
            frostedView.alphaValue = 0.15
            
            self.view.addSubview(frostedView)
            
            // 3) Start the cloud rotation timer.
            cloudTimer = Timer.scheduledTimer(timeInterval: 1.0 / 60.0,
                                              target: self,
                                              selector: #selector(updateCloudRotation),
                                              userInfo: nil,
                                              repeats: true)
            print("Started cloud rotation timer at 60 FPS.")
        } else {
            print("ERROR: skView outlet is nil. Verify your outlet connections in Interface Builder.")
        }
        
        // 4) Create the status label.
        let labelHeight: CGFloat = 40
        let margin: CGFloat = 10
        statusLabel = NSTextField(labelWithString: "CPU: 0%  Memory: 0%")
        statusLabel.font = NSFont(name: "Montserrat-Bold", size: 24)
        statusLabel.textColor = .white
        statusLabel.alignment = .left
        statusLabel.backgroundColor = .clear
        statusLabel.isBezeled = false
        statusLabel.frame = NSRect(x: 20,
                                   y: self.view.bounds.height - 100 - margin,
                                   width: 300,
                                   height: labelHeight)
        statusLabel.autoresizingMask = [.maxXMargin, .minYMargin]
        self.view.addSubview(statusLabel)
        print("Status label added with frame: \(statusLabel.frame)")
        
        // 5) Create the position label.
        let posLabelHeight: CGFloat = 20
        positionLabel = NSTextField(labelWithString: "0")
        positionLabel.font = NSFont.systemFont(ofSize: 14)
        positionLabel.textColor = .white
        positionLabel.alignment = .left
        positionLabel.backgroundColor = .clear
        positionLabel.isBezeled = false
        positionLabel.frame = NSRect(x: 20,
                                     y: self.view.bounds.height - 2 * 100 - 2 * margin,
                                     width: 300,
                                     height: posLabelHeight)
        positionLabel.autoresizingMask = [.maxXMargin, .minYMargin]
        self.view.addSubview(positionLabel)
        print("Position label added with frame: \(positionLabel.frame)")
        
        // 6) Create overlay charts for CPU and Memory usage.
        print("Creating CPU and Memory graph views.")
        let chartWidth: CGFloat = 200
        let chartHeight: CGFloat = 100
        
        let cpuFrame = NSRect(x: self.view.bounds.width - chartWidth - margin,
                              y: self.view.bounds.height - chartHeight - margin,
                              width: chartWidth,
                              height: chartHeight)
        cpuGraphView = LineGraphView(frame: cpuFrame)
        cpuGraphView.autoresizingMask = [.minXMargin, .minYMargin]
        cpuGraphView.lineColor = NSColor(calibratedRed: 0.85,
                                         green: 0.20,
                                         blue: 1.00,
                                         alpha: 1.00)
        cpuGraphView.lineWidth = 4.0
        self.view.addSubview(cpuGraphView, positioned: .above, relativeTo: skView)
        print("CPU graph view added with frame: \(cpuFrame)")
        
        let memFrame = NSRect(x: self.view.bounds.width - chartWidth - margin,
                              y: self.view.bounds.height - 2 * chartHeight - 2 * margin,
                              width: chartWidth,
                              height: chartHeight)
        memoryGraphView = LineGraphView(frame: memFrame)
        memoryGraphView.autoresizingMask = [.minXMargin, .minYMargin]
        memoryGraphView.lineColor = NSColor(calibratedRed: 0.70,
                                            green: 0.00,
                                            blue: 0.80,
                                            alpha: 1.00)
        memoryGraphView.lineWidth = 4.0
        self.view.addSubview(memoryGraphView, positioned: .above, relativeTo: skView)
        print("Memory graph view added with frame: \(memFrame)")
        
        // 7) Start a timer to update CPU and memory usage.
        updateTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                           target: self,
                                           selector: #selector(updateUsage),
                                           userInfo: nil,
                                           repeats: true)
        print("Started updateTimer for CPU and Memory usage.")
        
        print("viewDidLoad completed. Final container frame: \(self.view.frame)")
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = self.view.window {
            window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            window.title = "Kiraa Sales Analytics"
            print("Window style mask set to: \(window.styleMask)")
        }
    }
    
    // MARK: - Cloud Rotation Update
    @objc func updateCloudRotation() {
        pointCloud?.updateCloud()
    }
    
    // MARK: - Update CPU/Memory Usage
    @objc func updateUsage() {
        let cpuUsage = getSystemCPUUsage()
        let memUsage = getSystemMemoryUsage()
        cpuGraphView.addDataPoint(cpuUsage)
        memoryGraphView.addDataPoint(memUsage)
    }
}
