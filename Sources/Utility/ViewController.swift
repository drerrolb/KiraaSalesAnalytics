//
//  ViewController.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 9/3/2025.
//

import Cocoa
import SpriteKit
import GameplayKit
import Darwin   // Needed for Mach APIs

class ViewController: NSViewController {

    // Outlet for the SKView.
    var skView: SKView!
    
    // Single button that changes title.
    var launchButton: NSButton!
    
    // Additional button to explicitly close the window.
    var closeButton: NSButton!
    
    var cpuGraphView: LineGraphView!
    var memoryGraphView: LineGraphView!
    
    // Reference to the point cloud node.
    var pointCloud: KiraaCloud?
    
    // Timer for updating CPU/memory usage.
    var updateTimer: Timer?
    // Timer for updating the cloud rotation.
    var cloudTimer: Timer?
    // Timer for incrementing progress (single-fire, rescheduled each time).
    var progressTimer: Timer?
    
    // Progress value (0 to 100).
    var progress: Int = 0
    
    // Lorem Ipsum messages for status updates.
    let statusMessages = [
        "Lorem ipsum dolor sit amet.",
        "Consectetur adipiscing elit.",
        "Sed do eiusmod tempor incididunt.",
        "Ut labore et dolore magna aliqua.",
        "Ut enim ad minim veniam.",
        "Quis nostrud exercitation ullamco.",
        "Laboris nisi ut aliquip ex ea commodo.",
        "Duis aute irure dolor in reprehenderit.",
        "In voluptate velit esse cillum dolore.",
        "Eu fugiat nulla pariatur."
    ]
    
    // Status label (left-aligned).
    var statusLabel: NSTextField!
    // Position label (left-aligned).
    var positionLabel: NSTextField!
    
    // Dismiss callback used to notify SwiftUI to dismiss the sheet.
    var dismissCallback: (() -> Void)?
    
    override func loadView() {
        // Create a container view to host both the SKView and UI overlays.
        let containerFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let containerView = NSView(frame: containerFrame)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.darkGray.cgColor
        print("Container view frame: \(containerView.frame)")
        
        // Create the SKView, set it to fill the container, and add it as a subview.
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
            
            // Example dimensions for the frosted background.
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
            
            self.view.addSubview(frostedView, positioned: .below, relativeTo: cpuGraphView)
            
            cloudTimer = Timer.scheduledTimer(timeInterval: 1.0 / 60.0,
                                              target: self,
                                              selector: #selector(updateCloudRotation),
                                              userInfo: nil,
                                              repeats: true)
            print("Started cloud rotation timer at 60 FPS.")
        } else {
            print("ERROR: skView outlet is nil. Verify your outlet connections in Interface Builder.")
        }
        
        // 2) Create the launch button.
        let buttonWidth: CGFloat = 250
        let buttonHeight: CGFloat = 80
        let centerX = (self.view.bounds.width - buttonWidth) / 2.0
        let centerY: CGFloat = 40
        print("Creating launch button at (\(centerX), \(centerY)) with size (\(buttonWidth), \(buttonHeight)).")
        
        launchButton = NSButton(title: "Execute", target: self, action: #selector(launchButtonAction))
        launchButton.bezelStyle = .rounded
        launchButton.frame = NSRect(x: centerX, y: centerY, width: buttonWidth, height: buttonHeight)
        // For debugging, set a background color and border so the button is visible.
        launchButton.wantsLayer = true
        launchButton.layer?.backgroundColor = NSColor.systemBlue.cgColor
        launchButton.layer?.cornerRadius = 10
        launchButton.layer?.borderWidth = 2
        launchButton.layer?.borderColor = NSColor.white.cgColor
        
        self.view.addSubview(launchButton)
        print("Launch button added with frame: \(launchButton.frame)")
        
        // 3) Create the status label.
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
        
        // 4) Create the position label.
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
        
        // 5) Create overlay charts.
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
        
        // 6) Start a timer to update CPU and memory usage.
        updateTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                           target: self,
                                           selector: #selector(updateUsage),
                                           userInfo: nil,
                                           repeats: true)
        print("Started updateTimer for CPU and Memory usage.")
        
        // 7) Create an explicit close button to let users close the window.
        closeButton = NSButton(title: "Close Window", target: self, action: #selector(closeWindow))
        closeButton.bezelStyle = .rounded
        // Position the close button at the top-left of the window.
        closeButton.frame = NSRect(x: 20, y: self.view.bounds.height - 50, width: 120, height: 40)
        closeButton.autoresizingMask = [.maxYMargin, .minXMargin]
        self.view.addSubview(closeButton)
        print("Close button added with frame: \(closeButton.frame)")
        
        print("viewDidLoad completed. Final container frame: \(self.view.frame)")
    }
    
    // Override viewDidAppear to update the window's style mask.
    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = self.view.window {
            // Set a full set of style options to display the title bar, close button, etc.
            window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            window.title = "Kiraa Sales Analytics"
            print("Window style mask set to: \(window.styleMask)")
        }
    }
    
    // MARK: - Cloud Rotation Update
    @objc func updateCloudRotation() {
        pointCloud?.updateCloud()
    }
    
    // MARK: - Button Action
    @objc func launchButtonAction() {
        print("launchButtonAction called. Current button title: \(launchButton.title)")
        if launchButton.title == "Execute" {
            print("Button title is Execute. Starting random progress updates.")
            if progressTimer == nil {
                scheduleNextIncrement()
            }
            
            if let soundURL = Bundle.main.url(forResource: "start", withExtension: "wav") {
                let sound = NSSound(contentsOf: soundURL, byReference: false)
                print("Playing start.wav")
                sound?.play()
            } else {
                print("start.wav not found in bundle.")
            }
            
            launchButton.title = "Cancel"
            print("Button title changed to Cancel.")
        } else if launchButton.title == "Cancel" {
            print("Button title is Cancel. Stopping progress timer and resetting progress.")
            progressTimer?.invalidate()
            progressTimer = nil
            progress = 0
            pointCloud?.updateProgress(value: progress, status: "Reset")
            statusLabel.stringValue = "Reset"
            if let cloud = pointCloud {
                let x = Int(cloud.progressCenter.x)
                let y = Int(cloud.progressCenter.y)
                positionLabel.stringValue = "Center: (\(x), \(y))"
                print("Progress reset to 0. Cloud progressCenter: \(cloud.progressCenter), position: \(cloud.position)")
            }
            launchButton.title = "Execute"
            print("Button title changed back to Execute.")
        } else if launchButton.title == "Download" {
            print("Download button clicked.")
            downloadFunction()
        }
    }
    
    private func scheduleNextIncrement() {
        let randomInterval = Double.random(in: 0.5...3.0)
        print("Scheduling next increment in \(randomInterval) seconds.")
        progressTimer = Timer.scheduledTimer(timeInterval: randomInterval,
                                             target: self,
                                             selector: #selector(incrementProgress),
                                             userInfo: nil,
                                             repeats: false)
    }
    
    @objc func incrementProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
        
        if progress < 100 {
            progress += 1
            print("incrementProgress: Progress incremented to \(progress)")
            
            let randomIndex = Int(arc4random_uniform(UInt32(statusMessages.count)))
            let message = statusMessages[randomIndex]
            print("incrementProgress: Selected status message: \(message)")
            
            pointCloud?.updateProgress(value: progress, status: message)
            print("incrementProgress: Updated point cloud with progress \(progress) and status: \(message)")
            
            statusLabel.stringValue = message
            print("Status label updated: \(message)")
            
            updateUsage()
            
            if let soundURL = Bundle.main.url(forResource: "moveright", withExtension: "wav"),
               progress < 100 {
                let sound = NSSound(contentsOf: soundURL, byReference: false)
                sound?.play()
            }
            
            if progress < 100 {
                scheduleNextIncrement()
            } else {
                if let soundURL = Bundle.main.url(forResource: "end", withExtension: "wav") {
                    let sound = NSSound(contentsOf: soundURL, byReference: false)
                    print("Playing end.wav")
                    sound?.play()
                } else {
                    print("end.wav not found in bundle.")
                }
                launchButton.title = "Download"
                print("incrementProgress: Progress reached 100. Button title set to Download.")
            }
        }
    }
    
    @objc func downloadFunction() {
        print("downloadFunction called. (Download functionality not implemented.)")
    }
    
    @objc func updateUsage() {
        let cpuUsage = getSystemCPUUsage()
        let memUsage = getSystemMemoryUsage()
        cpuGraphView.addDataPoint(cpuUsage)
        memoryGraphView.addDataPoint(memUsage)
    }
    
    // MARK: - Close Window Action
    @objc func closeWindow() {
        if let window = self.view.window {
            window.performClose(nil)
            print("Close button pressed, window closing.")
        }
        // Call the dismiss callback to notify SwiftUI that the sheet should be dismissed.
        dismissCallback?()
    }
}
