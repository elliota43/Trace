import SwiftUI
import Vision

struct ImageWithHighlights: View {
    let nsImage: NSImage
    let highlightTerm: String
    let isRedactionEnabled: Bool
    
    @State private var searchBoxes: [CGRect] = []
    @State private var redactionBoxes: [CGRect] = []
    
    var body: some View {
        GeometryReader { geometry in
            let imageFrame = calculateImageFrame(containerSize: geometry.size, imageSize: nsImage.size)
            
            ZStack(alignment: .topLeading) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                ForEach(0..<searchBoxes.count, id: \.self) { i in
                    drawBox(rect: convert(boundingBox: searchBoxes[i], imageFrame: imageFrame), color: .yellow)
                }
                
                if isRedactionEnabled {
                    ForEach(0..<redactionBoxes.count, id: \.self) { i in
                        drawBlurBox(rect: convert(boundingBox: redactionBoxes[i], imageFrame: imageFrame))
                    }
                }
            }
            .onAppear { analyzeImage() }
            .onChange(of: highlightTerm) { analyzeImage() }
            .onChange(of: geometry.size) { analyzeImage() }
            .onChange(of: isRedactionEnabled) { analyzeImage() }
        }
    }
    
    func drawBox(rect: CGRect, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color.opacity(0.3))
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color, lineWidth: 1)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            )
    }
    
    func drawBlurBox(rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.ultraThinMaterial)
            .frame(width: rect.width + 4, height: rect.height + 4)
            .position(x: rect.midX, y: rect.midY)
            .overlay(
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .position(x: rect.midX, y: rect.midY)
            )
    }
    
    func calculateImageFrame(containerSize: CGSize, imageSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        var drawWidth: CGFloat
        var drawHeight: CGFloat
        
        if imageAspect > containerAspect {
            drawWidth = containerSize.width
            drawHeight = containerSize.width / imageAspect
        } else {
            drawHeight = containerSize.height
            drawWidth = containerSize.height * imageAspect
        }
        
        let x = (containerSize.width - drawWidth) / 2
        let y = (containerSize.height - drawHeight) / 2
        
        return CGRect(x: x, y: y, width: drawWidth, height: drawHeight)
    }
    
    func convert(boundingBox: CGRect, imageFrame: CGRect) -> CGRect {
        let x = imageFrame.minX + (boundingBox.minX * imageFrame.width)
        let y = imageFrame.minY + ((1 - boundingBox.maxY) * imageFrame.height)
        let w = boundingBox.width * imageFrame.width
        let h = boundingBox.height * imageFrame.height
        
        return CGRect(x: x, y: y, width: w, height: h)
    }

    func analyzeImage() {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        
        Task(priority: .userInitiated) {
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                var newSearchBoxes: [CGRect] = []
                var newRedactionBoxes: [CGRect] = []
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let text = candidate.string
                    
                    if !highlightTerm.isEmpty, let range = text.range(of: highlightTerm, options: .caseInsensitive) {
                        if let box = try? candidate.boundingBox(for: range) {
                            newSearchBoxes.append(box.boundingBox)
                        }
                    }
                    
                    let secrets = SensitiveDataDetector.findSecrets(in: text)
                    for secret in secrets {
                        if let box = try? candidate.boundingBox(for: secret.range) {
                            newRedactionBoxes.append(box.boundingBox)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.searchBoxes = newSearchBoxes
                    self.redactionBoxes = newRedactionBoxes
                }
            }
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
