import Cocoa

public class LineGraphView: NSView {
    /// Stores the incoming data points, each assumed in the range 0...100.
    public var dataPoints: [CGFloat] = []
    
    /// Maximum number of data points to show in the graph.
    public var maxDataPoints: Int = 60
    
    // MARK: - Style Customization
    
    /// Main line color (default: pinkish‑purple).
    public var lineColor: NSColor = NSColor(calibratedRed: 0.85,
                                            green: 0.20,
                                            blue: 1.00,
                                            alpha: 1.00)
    
    /// Thickness of the line.
    public var lineWidth: CGFloat = 4.0
    
    /// Whether to show small circles at each data point.
    public var showDataPointCircles: Bool = true
    
    /// The circle’s diameter is slightly larger than the line width.
    private var dataPointCircleSize: CGFloat {
        lineWidth * 2.0
    }
    
    // Rounded caps/joints for smooth lines.
    private let lineCapStyle: NSBezierPath.LineCapStyle = .round
    private let lineJoinStyle: NSBezierPath.LineJoinStyle = .round
    
    // Transparent background so we can see what's behind it.
    override public var isOpaque: Bool { false }
    
    // MARK: - Drawing
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard dataPoints.count > 1 else {
            // If there's 0 or 1 data point, there's no line to draw.
            NSColor.clear.setFill()
            dirtyRect.fill()
            return
        }
        
        // Clear background
        NSColor.clear.setFill()
        dirtyRect.fill()
        
        let width = bounds.width
        let height = bounds.height
        
        // Horizontal spacing between points.
        let spacing = width / CGFloat(maxDataPoints - 1)
        
        // 1) Create the main path for the line
        let graphPath = NSBezierPath()
        graphPath.lineWidth = lineWidth
        graphPath.lineCapStyle = lineCapStyle
        graphPath.lineJoinStyle = lineJoinStyle
        
        for (i, value) in dataPoints.enumerated() {
            // Normalize value into the vertical range [0 .. height].
            let x = CGFloat(i) * spacing
            let y = (value / 100.0) * height
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                graphPath.move(to: point)
            } else {
                graphPath.line(to: point)
            }
        }
        
        // 2) Create a fill path by copying graphPath and closing down to the bottom.
        let fillPath = graphPath.copy() as! NSBezierPath
        fillPath.line(to: CGPoint(x: fillPath.currentPoint.x, y: 0))
        fillPath.line(to: CGPoint(x: 0, y: 0))
        fillPath.close()
        
        // 3) Fill the area with a subtle gradient that fades downward.
        if let gradient = NSGradient(starting: lineColor.withAlphaComponent(0.2),
                                     ending: lineColor.withAlphaComponent(0.0)) {
            gradient.draw(in: fillPath, angle: -90.0)
        }
        
        // 4) Add a soft shadow behind the stroke for a glow effect.
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            // Adjust color/blur to taste.
            context.setShadow(offset: .zero, blur: 4, color: lineColor.withAlphaComponent(0.6).cgColor)
            
            // 5) Stroke the line
            lineColor.setStroke()
            graphPath.stroke()
            
            context.restoreGState()
        }
        
        // 6) Optionally draw small circles for each data point
        if showDataPointCircles {
            for (i, value) in dataPoints.enumerated() {
                let x = CGFloat(i) * spacing
                let y = (value / 100.0) * height
                
                // Center the circle around (x, y)
                let circleRect = CGRect(x: x - (dataPointCircleSize / 2),
                                        y: y - (dataPointCircleSize / 2),
                                        width: dataPointCircleSize,
                                        height: dataPointCircleSize)
                let circlePath = NSBezierPath(ovalIn: circleRect)
                
                // Fill each point with the same line color (or a variant).
                lineColor.setFill()
                circlePath.fill()
            }
        }
    }
    
    // MARK: - Data handling
    
    /// Adds a new data point (0...100 range), removes old points if over capacity.
    public func addDataPoint(_ value: CGFloat) {
        dataPoints.append(value)
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst()
        }
        
        needsDisplay = true
    }
}	
