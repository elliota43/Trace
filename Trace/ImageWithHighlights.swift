//
//  ImageWithHighlights.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import SwiftUI
import Vision

struct ImageWithHighlights: View {
    let nsImage: NSImage
    let highlightTerm: String
    
    @State private var boxes: [CGRect] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Yellow Highlights
                ForEach(0..<boxes.count, id: \.self) { i in
                    let rect = convert(boundingBox: boxes[i], to: geometry.size)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.yellow.opacity(0.4))
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.yellow, lineWidth: 1)
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                        )
                }
            }
            .onAppear {
                findMatches()
            }
            .onChange(of: highlightTerm) {
                findMatches()
            }
        }
    }
    
    // Convert Vision (Bottom-Left 0,0) to SwiftUI (Top-Left 0,0)
    func convert(boundingBox: CGRect, to size: CGSize) -> CGRect {
        // Calculate the actual image size inside the "Aspect Fit" view
        let imageAspectRatio = nsImage.size.width / nsImage.size.height
        let viewAspectRatio = size.width / size.height
        
        var drawWidth: CGFloat
        var drawHeight: CGFloat
        
        if imageAspectRatio > viewAspectRatio {
            // Image is wider than view (fit width)
            drawWidth = size.width
            drawHeight = size.width / imageAspectRatio
        } else {
            // Image is taller than view (fit height)
            drawHeight = size.height
            drawWidth = size.height * imageAspectRatio
        }
        
        let offsetX = (size.width - drawWidth) / 2
        let offsetY = (size.height - drawHeight) / 2
        
        // Vision Coords: Y starts at bottom. X is standard.
        let x = boundingBox.minX * drawWidth + offsetX
        // Flip Y because Vision is flipped relative to SwiftUI
        let y = (1 - boundingBox.maxY) * drawHeight + offsetY
        let w = boundingBox.width * drawWidth
        let h = boundingBox.height * drawHeight
        
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    func findMatches() {
        guard !highlightTerm.isEmpty, let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            boxes = []
            return
        }
        
        Task {
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                var newBoxes: [CGRect] = []
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    
                    // Simple Case-Insensitive Check
                    if let range = candidate.string.range(of: highlightTerm, options: .caseInsensitive) {
                        // Vision allows asking for the box of a specific substring!
                        if let box = try? candidate.boundingBox(for: range) {
                            newBoxes.append(box.boundingBox)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.boxes = newBoxes
                }
            }
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
