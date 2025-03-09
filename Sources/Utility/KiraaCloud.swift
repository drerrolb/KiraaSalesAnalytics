//
//  for.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 9/3/2025.
//


//
//  KiraaCloud.swift
//  kiraa
//
//  Created by Errol Brandt on 7/3/2025.
//

import SpriteKit
import GameplayKit

// A simple 3D vector struct for our particle positions.
struct Vector3 {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
}

public class KiraaCloud: SKNode {
    
    // Arrays to store cloud particles and lattice (gray) particles.
    var particles: [(node: SKSpriteNode,
                     originalPos: Vector3,
                     baseScale: CGFloat,
                     rotationSpeed: CGFloat,
                     rotationOffset: CGFloat)] = []
    
    var latticeParticles: [(node: SKSpriteNode, latticePos: Vector3)] = []
    
    // Store the start time for continuous rotation.
    var startTime: TimeInterval = CACurrentMediaTime()
    
    // Configuration parameters – based on the provided size.
    let F: CGFloat = 300
    let period: CGFloat = 30.0
    let amplitude: CGFloat
    let a: CGFloat
    let b: CGFloat
    let minZ: CGFloat = 20
    let center3D: Vector3
    
    // The fixed center for projection (updated only when progress is updated).
    public var progressCenter: CGPoint = .zero
    var targetProgressCenter: CGPoint = .zero
    
    // Nodes used for applying effects.
    var cloudContainer: SKNode!
    var effectNode: SKEffectNode!
    var latticeNode: SKNode!
    
    // Properties for external control.
    var progress: CGFloat = 0.0  // Range [0..100]
    
    // A dedicated property for the status label (minor update).
    var statusLabel: SKLabelNode!
    
    // We'll keep a copy of the current status text.
    var currentStatusText: String = "Status"
    
    // Extra rotation property (in radians) to mask jitter.
    var extraRotation: CGFloat = 0.0
    
    // MARK: - Initializer
    public init(size: CGSize) {
        // Set extents based on the scene size.
        self.a = size.width * 0.15
        self.b = size.height * 0.25
        self.amplitude = size.width * 0.25
        
        // Define the 3D center (origin) of the point cloud.
        self.center3D = Vector3(x: 0, y: 0, z: (minZ + a) / 2)
        
        // Start with progress=0 at the left edge.
        self.progress = 0.0
        
        self.progressCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        self.targetProgressCenter = self.progressCenter
        
        super.init()
        self.setupNodes(size: size)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    func setupNodes(size: CGSize) {
        // 1) Container for cloud particles.
        cloudContainer = SKNode()
        cloudContainer.zPosition = 0
        addChild(cloudContainer)
        
        // 2) Effect node for cloud particles (with blur).
        effectNode = SKEffectNode()
        effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10.0])
        effectNode.shouldEnableEffects = true
        effectNode.blendMode = .add
        effectNode.zPosition = 1
        cloudContainer.addChild(effectNode)
        
        // 3) Node for lattice particles (no blur).
        latticeNode = SKNode()
        latticeNode.zPosition = 2
        cloudContainer.addChild(latticeNode)
        
        // 4) Prepare a radial gradient texture for feathered particles.
        let gradientTexture = makeRadialGradientTexture(diameter: 64)
        let center2D = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        
        // Helper function to generate a random 3D point inside the ellipsoidal volume.
        func random3DPoint() -> Vector3 {
            while true {
                let x = CGFloat.random(in: -a...a)
                let y = CGFloat.random(in: -b...b)
                let z = CGFloat.random(in: minZ...a)
                let normalizedZ = (z - minZ) / (a - minZ)
                if (x * x)/(a * a) + (y * y)/(b * b) + (normalizedZ * normalizedZ) <= 1 {
                    return Vector3(x: x, y: y, z: z)
                }
            }
        }
        
        // Helper function to create cloud particles.
        func createParticle(baseHue: CGFloat,
                            hueVariation: ClosedRange<CGFloat>,
                            saturation: CGFloat,
                            alphaRange: ClosedRange<CGFloat>,
                            scaleRange: ClosedRange<CGFloat>,
                            count: Int) {
            for _ in 1...count {
                let pos3D = random3DPoint()
                let baseScale = CGFloat.random(in: scaleRange)
                
                let cloudSprite = SKSpriteNode(texture: gradientTexture)
                cloudSprite.setScale(baseScale)
                
                let randomHue = max(0, min(1, baseHue + CGFloat.random(in: hueVariation)))
                let originalColor = NSColor(calibratedHue: randomHue,
                                            saturation: saturation,
                                            brightness: 0.8,
                                            alpha: CGFloat.random(in: alphaRange))
                let neonTint = NSColor(calibratedHue: 0.85,
                                       saturation: 0.8,
                                       brightness: 0.7,
                                       alpha: 1.0)
                let tintedColor = originalColor.blended(withFraction: 0.7, of: neonTint) ?? originalColor
                
                cloudSprite.color = tintedColor
                cloudSprite.colorBlendFactor = 1.0
                cloudSprite.blendMode = .add
                
                let scaleProj = F / (F + pos3D.z)
                let projectedX = center2D.x + pos3D.x * scaleProj
                let projectedY = center2D.y + pos3D.y * scaleProj
                cloudSprite.position = CGPoint(x: projectedX, y: projectedY)
                cloudSprite.setScale(baseScale * scaleProj)
                
                effectNode.addChild(cloudSprite)
                
                let rotationSpeed = CGFloat.random(in: 0.5...1.5)
                let rotationOffset = CGFloat.random(in: 0...(2 * .pi))
                
                particles.append((node: cloudSprite,
                                  originalPos: pos3D,
                                  baseScale: baseScale,
                                  rotationSpeed: rotationSpeed,
                                  rotationOffset: rotationOffset))
            }
        }
        
        // 5) Create three sets of cloud particles with vibrant colors.
        createParticle(baseHue: 0.66, hueVariation: -0.05...0.05, saturation: 1.0,
                       alphaRange: 0.80...0.85, scaleRange: 0.1...1.0, count: 20)  // Blue
        createParticle(baseHue: 0.33, hueVariation: -0.05...0.05, saturation: 1.0,
                       alphaRange: 0.50...0.58, scaleRange: 1.0...2.0, count: 10)  // Green
        createParticle(baseHue: 0.15, hueVariation: -0.03...0.03, saturation: 1.0,
                       alphaRange: 0.38...0.42, scaleRange: 2.0...3.0, count: 5)   // Yellow
        
        // 6) Add lattice particles, but only approximately 20% of the possible points.
        let latticeCount = 6  // 6 per dimension.
        for i in 0..<latticeCount {
            for j in 0..<latticeCount {
                for k in 0..<latticeCount {
                    // Only add this lattice point with a 20% chance.
                    if CGFloat.random(in: 0...1) > 0.2 {
                        continue
                    }
                    
                    let u = -1 + 2 * CGFloat(i) / CGFloat(latticeCount - 1)
                    let v = -1 + 2 * CGFloat(j) / CGFloat(latticeCount - 1)
                    let w = -1 + 2 * CGFloat(k) / CGFloat(latticeCount - 1)
                    let latticePos = Vector3(x: u * a, y: v * b, z: w * a)
                    
                    let latticeSprite = SKSpriteNode(texture: gradientTexture)
                    latticeSprite.setScale(0.05)
                    latticeSprite.color = NSColor(white: 0.5, alpha: 0.8)
                    latticeSprite.colorBlendFactor = 1.0
                    latticeSprite.blendMode = .add
                    
                    let scaleProj = F / (F + (minZ + a) / 2)
                    let projectedX = center2D.x + latticePos.x * scaleProj
                    let projectedY = center2D.y + latticePos.y * scaleProj
                    latticeSprite.position = CGPoint(x: projectedX, y: projectedY)
                    latticeSprite.zPosition = 2
                    latticeNode.addChild(latticeSprite)
                    
                    latticeParticles.append((node: latticeSprite, latticePos: latticePos))
                }
            }
        }
        
        // 7) Create the "Minor Update" status label.
        statusLabel = SKLabelNode(fontNamed: "Montserrat-Bold")
        statusLabel.fontSize = 16
        statusLabel.fontColor = NSColor(white: 0.9, alpha: 1.0)
        statusLabel.text = currentStatusText
        statusLabel.zPosition = 100
        // Set horizontal alignment to left
        statusLabel.horizontalAlignmentMode = .left
        statusLabel.position = CGPoint(x: 20, y: size.height - 70)
        addChild(statusLabel)
    }
    
    // If needed, reparent the status label to the scene.
    func attachStatusLabelToScene() {
        if let scene = self.scene {
            statusLabel.removeFromParent()
            // Adjust the position as needed when reattaching.
            statusLabel.position = CGPoint(x: 20, y: scene.size.height - 70)
            scene.addChild(statusLabel)
        }
    }
    
    // MARK: - Update Cloud
    public func updateCloud() {
        guard let scene = self.scene else { return }
        let sceneCenter = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
        // Smoothly interpolate progressCenter toward targetProgressCenter.
        let smoothingFactor: CGFloat = 0.1
        progressCenter.x += (targetProgressCenter.x - progressCenter.x) * smoothingFactor
        progressCenter.y += (targetProgressCenter.y - progressCenter.y) * smoothingFactor
        
        // Compute the offset from sceneCenter to progressCenter.
        let offsetX = progressCenter.x - sceneCenter.x
        let offsetY = progressCenter.y - sceneCenter.y

        let F: CGFloat = 300
        let a = self.a
        let b = self.b
        let minZ = self.minZ
        let center3D = self.center3D
        
        // t is how far along the "cube mapping" transition [0..1].
        let t = progress / 100.0
        
        // Increase spin speed in the middle of progress using a sine curve.
        let spinBoost: CGFloat = 1.0  // Adjust to control maximum speed boost.
        let spinMultiplier = 1 + spinBoost * sin(CGFloat.pi * t)
        
        // Continuous rotation angle (full revolution every 10 seconds).
        let elapsedTime = CACurrentMediaTime() - startTime
        let globalRotation = CGFloat(elapsedTime) * (2 * CGFloat.pi / 10)
        
        // Update each cloud particle.
        for particle in particles {
            let orig = particle.originalPos
            let relative = Vector3(x: orig.x - center3D.x,
                                   y: orig.y - center3D.y,
                                   z: orig.z - center3D.z)
            
            // Rotate around Y axis with spinMultiplier.
            let effectiveAngle = globalRotation * spinMultiplier * particle.rotationSpeed + particle.rotationOffset
            let rotatedRelative = Vector3(
                x: relative.x * cos(effectiveAngle) + relative.z * sin(effectiveAngle),
                y: relative.y,
                z: -relative.x * sin(effectiveAngle) + relative.z * cos(effectiveAngle)
            )
            
            // Cube mapping blended by t.
            let u = rotatedRelative.x / a
            let v = rotatedRelative.y / b
            let w = rotatedRelative.z / a
            let cubeX = (u >= 0 ? pow(u, 1/3) : -pow(-u, 1/3)) * a * 0.25
            let cubeY = (v >= 0 ? pow(v, 1/3) : -pow(-v, 1/3)) * b * 0.25
            let cubeZ = (w >= 0 ? pow(w, 1/3) : -pow(-w, 1/3)) * a * 0.25
            let cubeRelative = Vector3(x: cubeX, y: cubeY, z: cubeZ)
            
            // Blend ellipsoidal vs. cubic position by t.
            let finalRelative = Vector3(
                x: (1 - t) * rotatedRelative.x + t * cubeRelative.x,
                y: (1 - t) * rotatedRelative.y + t * cubeRelative.y,
                z: (1 - t) * rotatedRelative.z + t * cubeRelative.z
            )
            
            // Translate back to world space.
            let new3D = Vector3(
                x: finalRelative.x + center3D.x,
                y: finalRelative.y + center3D.y,
                z: finalRelative.z + center3D.z
            )
            
            let scaleProj = F / (F + new3D.z)
            let projectedX = sceneCenter.x + new3D.x * scaleProj + offsetX
            let projectedY = sceneCenter.y + new3D.y * scaleProj + offsetY
            
            particle.node.position = CGPoint(x: projectedX, y: projectedY)
            particle.node.setScale(particle.baseScale * scaleProj)
            
            let visibilityFactor = particle.rotationOffset / (2 * CGFloat.pi)
            let threshold = 1 - 0.5 * t
            particle.node.alpha = (visibilityFactor > threshold) ? 0 : 1
        }
        
        // Update lattice particles similarly.
        let latticeRotationSpeed: CGFloat = 0.5
        let latticeEffectiveAngle = globalRotation * spinMultiplier * latticeRotationSpeed
        for lattice in latticeParticles {
            let lp = lattice.latticePos
            let rotatedLp = Vector3(
                x: lp.x * cos(latticeEffectiveAngle) + lp.z * sin(latticeEffectiveAngle),
                y: lp.y,
                z: -lp.x * sin(latticeEffectiveAngle) + lp.z * cos(latticeEffectiveAngle)
            )
            let new3D = Vector3(
                x: rotatedLp.x + center3D.x,
                y: rotatedLp.y + center3D.y,
                z: rotatedLp.z + center3D.z
            )
            let scaleProj = F / (F + new3D.z)
            let projectedX = sceneCenter.x + new3D.x * scaleProj + offsetX
            let projectedY = sceneCenter.y + new3D.y * scaleProj + offsetY
            lattice.node.position = CGPoint(x: projectedX, y: projectedY)
        }
    }
    
    // MARK: - Texture Helper
    private func makeRadialGradientTexture(diameter: CGFloat) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            fatalError("Failed to create CGContext")
        }
        
        let gradientColors = [
            NSColor.white.withAlphaComponent(1.0).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ] as CFArray
        
        let gradientLocations: [CGFloat] = [0.0, 1.0]
        
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: gradientColors,
            locations: gradientLocations
        ) else {
            fatalError("Failed to create CGGradient")
        }
        
        let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = max(size.width, size.height) / 2
        
        context.drawRadialGradient(
            gradient,
            startCenter: centerPoint,
            startRadius: 0,
            endCenter: centerPoint,
            endRadius: radius,
            options: []
        )
        
        guard let cgImage = context.makeImage() else {
            fatalError("Failed to create CGImage from context")
        }
        
        return SKTexture(cgImage: cgImage)
    }
    
    // MARK: - External Progress Update
    public func updateProgress(value: Int, status: String) {
        // Clamp value to [0,100].
        self.progress = CGFloat(max(0, min(100, value)))
        currentStatusText = status
        
        // Update the minor update label text.
        statusLabel.text = status

        if let scene = self.scene {
            let midY = scene.size.height / 2
            let margin = scene.size.width * 0.15
            let minX = margin
            let maxX = scene.size.width - margin
            let centerX = minX + (self.progress / 100.0) * (maxX - minX)
            self.targetProgressCenter = CGPoint(x: centerX, y: midY)
        } else {
            let midY = self.frame.midY
            let margin = self.frame.width * 0.15
            let minX = margin
            let maxX = self.frame.width - margin
            let centerX = minX + (self.progress / 100.0) * (maxX - minX)
            self.targetProgressCenter = CGPoint(x: centerX, y: midY)
        }
    }
}
