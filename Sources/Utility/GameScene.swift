//
//  GameScene.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 9/3/2025.
//


//
//  GameScene.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 8/3/2025.
//


import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    var cloud: KiraaCloud!
    
    // The gradient label (Major Update).
    var gradientLabel: SKSpriteNode!
    
    // The current status text (used for the gradient label).
    var currentStatusText: String = "Kiraa Analytics:"  // Initial text.
    
    // Example Lorem Ipsum messages.
    let statusMessages = [
        "Consectetur adipiscing elit.",
        "Sed do eiusmod tempor incididunt.",
        "Ut labore et dolore magna aliqua.",
        "Duis aute irure dolor in reprehenderit.",
        "In voluptate velit esse cillum dolore.",
        "Eu fugiat nulla pariatur."
    ]
    
    // AVAudioPlayer instance for preloading and playing the sound.
    var moverightPlayer: AVAudioPlayer?
    
    override func didMove(to view: SKView) {
        // Anchor at bottom-left so (0,0) is the lower-left corner.
        self.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Add a frosted glass background behind the charts in the top right-hand side.
        let frostedSize = CGSize(width: 240, height: 240)
        // Create a rounded rectangle path.
        let frostedRect = CGRect(origin: CGPoint(x: -frostedSize.width/2, y: -frostedSize.height/2), size: frostedSize)
        let frostedPath = CGPath(roundedRect: frostedRect, cornerWidth: 20, cornerHeight: 20, transform: nil)
        let frostedNode = SKShapeNode(path: frostedPath)
        frostedNode.fillColor = SKColor(white: 1.0, alpha: 0.1)  // Low opacity for a subtle effect.
        frostedNode.strokeColor = .clear
        frostedNode.zPosition = 100  // Ensure it's behind the charts.
        // Position it near the top-right with a margin.
        frostedNode.position = CGPoint(x: self.size.width - frostedSize.width/2 - 20,
                                       y: self.size.height - frostedSize.height/2 - 20)
        addChild(frostedNode)
        
        // Load and prepare the sound.
        if let soundURL = Bundle.main.url(forResource: "moveright", withExtension: "wav") {
            do {
                moverightPlayer = try AVAudioPlayer(contentsOf: soundURL)
                moverightPlayer?.prepareToPlay()
            } catch {
                print("Error loading moveright.wav: \(error)")
            }
        } else {
            print("Could not find moveright.wav in bundle")
        }
        
        // 1) Initialize your cloud node and add it to the scene.
        cloud = KiraaCloud(size: self.size)
        cloud.name = "kiraaCloud"
        addChild(cloud)
        
        // 2) Create the gradient label sprite for the "Major Update" text.
        //    We prefix "MAJOR UPDATE:" to differentiate it from the KiraaCloud label.
        let majorText = "MAJOR UPDATE: \(currentStatusText)"
        if let gradientLabelSprite = createGradientLabel(with: majorText, view: view) {
            gradientLabel = gradientLabelSprite
            // Position near the top-center, e.g. 50 points below top.
            gradientLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 50)
            gradientLabel.zPosition = 1000
            addChild(gradientLabel)
        } else {
            print("Failed to create gradient label")
        }
        
        // 3) Initialize the cloud at progress=0, then recenter the y if desired.
        cloud.updateProgress(value: 0, status: currentStatusText)
        cloud.progressCenter = CGPoint(x: cloud.progressCenter.x, y: self.size.height / 2)
    }
    
    override func update(_ currentTime: TimeInterval) {
        cloud.updateCloud()
    }
    
    // MARK: - Gradient Label Helpers
    
    func createGradientLabel(with text: String, view: SKView) -> SKSpriteNode? {
        let label = SKLabelNode(fontNamed: "Montserrat-Bold")
        label.text = text
        label.fontSize = 24
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .top
        
        // Temporarily add the label to generate a texture, then remove it.
        label.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        addChild(label)
        let texture = view.texture(from: label)
        label.removeFromParent()
        
        guard let texture = texture else { return nil }
        let sprite = SKSpriteNode(texture: texture)
        return sprite
    }
    
    /// Updates the texture of the existing gradient label with new text (Major Update).
    func updateGradientLabel(with text: String, view: SKView) {
        let tempLabel = SKLabelNode(fontNamed: "Montserrat-Bold")
        tempLabel.text = "MAJOR UPDATE: \(text)"
        tempLabel.fontSize = 24
        tempLabel.fontColor = .white
        tempLabel.horizontalAlignmentMode = .center
        tempLabel.verticalAlignmentMode = .top
        
        // Create texture in memory (don't add tempLabel to scene).
        if let newTexture = view.texture(from: tempLabel) {
            gradientLabel.texture = newTexture
        }
    }
    
    /// Called externally (e.g. from ViewController) to update progress and label.
    func userDidUpdateProgress(value: Int, status: String) {
        // Update the cloud's "Minor Update" label and logic.
        cloud.updateProgress(value: value, status: status)
        
        // Play sound "moveright.wav" each time progress updates.
        if let player = moverightPlayer {
            player.currentTime = 0 // Reset sound playback to the beginning
            player.play()
        }
        
        // Update the "Major Update" gradient label with the same text (or different if you like).
        if let view = self.view {
            currentStatusText = status
            updateGradientLabel(with: status, view: view)
        }
    }
}
