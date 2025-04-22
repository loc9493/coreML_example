//
//  CoreMLHelper.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/22/25.
//

import Foundation
import CoreImage
import AVFoundation
import Vision

import Foundation
import CoreImage
import AVFoundation
import Vision
import CoreImage.CIFilterBuiltins


struct CoreMLHelper {
    static var personSegmentationRequest: VNGeneratePersonSegmentationRequest?
    static func peopleSegmentation(sampleBuffer: CMSampleBuffer) async throws -> CMSampleBuffer? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = personSegmentationRequest else { return nil }
        
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            try handler.perform([request])
            
            guard let mask = request.results?.first?.pixelBuffer else { return nil }

            // Convert mask to CGImage for display
            let ciImage = CIImage(cvPixelBuffer: mask)
            let orgFrame = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext(options: nil)
            
            // scale mask
             let maskScaleX = orgFrame.extent.width / ciImage.extent.width
             let maskScaleY = orgFrame.extent.height / ciImage.extent.height
             let maskScaled = ciImage.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))

            let resultImage = applyMask(mask: maskScaled, to: orgFrame)

            if let cgImage = context.createCGImage(resultImage, from: resultImage.extent) {
//                DispatchQueue.main.async {
//                    self.segmentationMask = cgImage
//                }
            }
            
        } catch {
            print("Error performing person segmentation: \(error)")
        }
        return sampleBuffer
    }

}


// Define a filter operation
struct FilterOperation {
    let name: String
    let filter: (CIImage) -> CIImage
}

// AsyncSequence for processing image with filters
struct ImageFilterSequence: AsyncSequence {
    typealias Element = CIImage
    
    let sourceImage: CIImage
    let filters: [FilterOperation]
    
    init(sampleBuffer: CMSampleBuffer, filters: [FilterOperation]) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            fatalError("Failed to get pixel buffer from sample buffer")
        }
        self.sourceImage = CIImage(cvPixelBuffer: pixelBuffer)
        self.filters = filters
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(image: sourceImage, filters: filters)
    }
    
    struct AsyncIterator: AsyncIteratorProtocol {
        private var image: CIImage
        private var remainingFilters: [FilterOperation]
        private let context = CIContext(options: nil)
        
        init(image: CIImage, filters: [FilterOperation]) {
            self.image = image
            self.remainingFilters = filters
        }
        
        mutating func next() async -> CIImage? {
            guard !remainingFilters.isEmpty else {
                return nil // No more filters to apply
            }
            
            let filter = remainingFilters.removeFirst()
            print("Applying filter: \(filter.name)")
            
            // Apply the filter
            image = filter.filter(image)
            
            return image
        }
    }
}

class ImageProcessingPipeline {
    private let ciContext = CIContext(options: nil)
    
    // Create various filter operations
    func createBlurFilter(radius: Float) -> FilterOperation {
        return FilterOperation(name: "Gaussian Blur") { image in
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = image
            filter.radius = radius
            return filter.outputImage ?? image
        }
    }
    
    func createSepiaFilter(intensity: Float) -> FilterOperation {
        return FilterOperation(name: "Sepia") { image in
            let filter = CIFilter.sepiaTone()
            filter.inputImage = image
            filter.intensity = intensity
            return filter.outputImage ?? image
        }
    }
    
    func createSharpenFilter(amount: Float) -> FilterOperation {
        return FilterOperation(name: "Sharpen") { image in
            let filter = CIFilter.sharpenLuminance()
            filter.inputImage = image
            filter.sharpness = amount
            return filter.outputImage ?? image
        }
    }
    
    func createColorAdjustment(brightness: Float, contrast: Float, saturation: Float) -> FilterOperation {
        return FilterOperation(name: "Color Adjustment") { image in
            let filter = CIFilter.colorControls()
            filter.inputImage = image
            filter.brightness = brightness
            filter.contrast = contrast
            filter.saturation = saturation
            return filter.outputImage ?? image
        }
    }
    
    // Person segmentation filter
    func createPersonSegmentationFilter(request: VNGeneratePersonSegmentationRequest) -> FilterOperation {
        return FilterOperation(name: "Person Segmentation") { [weak self] image in
            guard let self = self else { return image }
            
            // Create a pixel buffer from the CIImage
            var pixelBuffer: CVPixelBuffer?
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            let width = Int(image.extent.width)
            let height = Int(image.extent.height)
            
            CVPixelBufferCreate(kCFAllocatorDefault,
                               width, height,
                               kCVPixelFormatType_32BGRA,
                               attrs, &pixelBuffer)
            
            guard let pixelBuffer = pixelBuffer else { return image }
            
            self.ciContext.render(image, to: pixelBuffer)
            
            do {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
                try handler.perform([request])
                
                guard let mask = request.results?.first?.pixelBuffer else { return image }
                
                // Convert mask to CIImage for display
                let maskImage = CIImage(cvPixelBuffer: mask)
                
                // Scale mask to match image size
                let maskScaleX = image.extent.width / maskImage.extent.width
                let maskScaleY = image.extent.height / maskImage.extent.height
                let maskScaled = maskImage.transformed(by: CGAffineTransform(scaleX: maskScaleX, y: maskScaleY))
                
                // Apply mask - here you can implement your preferred masking technique
                let blendFilter = CIFilter.blendWithMask()
                blendFilter.inputImage = image
                blendFilter.backgroundImage = CIImage(color: .clear)
                blendFilter.maskImage = maskScaled
                
                return blendFilter.outputImage ?? image
            } catch {
                print("Error performing person segmentation: \(error)")
                return image
            }
        }
    }
    
    // Process a sample buffer through a pipeline of filters
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, filters: [FilterOperation]) async -> CMSampleBuffer? {
        let sequence = ImageFilterSequence(sampleBuffer: sampleBuffer, filters: filters)
        
        var finalImage: CIImage?
        
        for await processedImage in sequence {
            finalImage = processedImage
        }
        
        guard let finalImage = finalImage else {
            return sampleBuffer
        }
        
        // Convert back to CMSampleBuffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return sampleBuffer
        }
        
        // Render final image to the pixel buffer
        ciContext.render(finalImage, to: pixelBuffer)
        
        return sampleBuffer
    }
    
    // Sample usage
    func createDefaultFilterPipeline() -> [FilterOperation] {
        var filters: [FilterOperation] = []
        
        // Add person segmentation if needed
        if let segmentationRequest = CoreMLHelper.personSegmentationRequest {
            filters.append(createPersonSegmentationFilter(request: segmentationRequest))
        }
        
        // Add other filters to the pipeline
        filters.append(createColorAdjustment(brightness: 0.05, contrast: 1.1, saturation: 1.2))
        filters.append(createSharpenFilter(amount: 0.7))
        
        return filters
    }
}

// Extension for CoreMLHelper to use the pipeline
extension CoreMLHelper {
    static func processSampleBufferWithFilters(_ sampleBuffer: CMSampleBuffer) async -> CMSampleBuffer? {
        let pipeline = ImageProcessingPipeline()
        let filters = pipeline.createDefaultFilterPipeline()
        return await pipeline.processSampleBuffer(sampleBuffer, filters: filters)
    }
    
    static func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = image
        blendFilter.backgroundImage = CIImage(color: .clear)
        blendFilter.maskImage = mask
        return blendFilter.outputImage ?? image
    }
}
