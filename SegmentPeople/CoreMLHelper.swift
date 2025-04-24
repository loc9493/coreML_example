//
//  CoreMLHelper.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/22/25.
//

import AVFoundation
import CoreImage
import Foundation
import Vision

import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit
import Vision

typealias ImageProcessingHandler = (_ input: CIImage?) -> CIImage?

enum MLImageProcessing {
    case personSegmentation(filter: CIPersonSegmentation)
    case personSegmentation(request: VNGeneratePersonSegmentationRequest)
    
    func filter() -> ImageProcessingHandler {
        return { image in
            return image
        }
    }
}

class ImageFilterPipeline {
    private var filters: [ImageProcessingHandler] = []
    
    /// Add a filter to the end of the pipeline
    /// - Parameter filter: The image processing handler to add
    /// - Returns: Self for method chaining
    @discardableResult
    func addFilter(_ filter: @escaping ImageProcessingHandler) -> Self {
        filters.append(filter)
        return self
    }
    
    /// Process an image through all filters in the pipeline
    /// - Parameter inputImage: The original image to process
    /// - Returns: The final processed image after passing through all filters
    func process(inputImage: CIImage?) -> CIImage? {
        var currentImage = inputImage
        
        for filter in filters {
            guard let image = currentImage else { return nil }
            currentImage = filter(image)
        }
        
        return currentImage
    }
    
    /// Remove all filters from the pipeline
    func reset() {
        filters.removeAll()
    }
}

struct CoreMLHelper {
    static func getAllCIFilters() -> [String: [String: Any]] {
        // Get all filter names
        let filterNames = CIFilter.filterNames(inCategory: nil)
        var filterInfo: [String: [String: Any]] = [:]
        
        for name in filterNames {
            guard let filter = CIFilter(name: name) else { continue }
            
            // Get filter attributes
            let attributes = filter.attributes
            filterInfo[name] = attributes
        }
        
        return filterInfo
    }
    static func createProcessingPipeline(with segmentationRequest: VNGeneratePersonSegmentationRequest) -> ImageFilterPipeline {
        let pipeline = ImageFilterPipeline()
        
        // Add filters in the desired order
        
        // 1. Person segmentation filter
        pipeline.addFilter(peopleSegmentation(request: segmentationRequest))
        
        // 2. Add a sepia tone filter
        pipeline.addFilter { image in
            guard let image = image else { return nil }
            let sepiaFilter = CIFilter.sepiaTone()
            sepiaFilter.inputImage = image
            sepiaFilter.intensity = 0.8
            return sepiaFilter.outputImage
        }
        
        // 3. Add a vignette effect
        pipeline.addFilter { image in
            guard let image = image else { return nil }
            let vignetteFilter = CIFilter.vignette()
            vignetteFilter.inputImage = image
            vignetteFilter.intensity = 0.7
            vignetteFilter.radius = 1.0
            return vignetteFilter.outputImage
        }
        return pipeline
    }
    static func peopleSegmentation(filter: CIPersonSegmentation) -> ImageProcessingHandler {
        return { ciImage in
            guard let ciImage = ciImage else { return nil }
            filter.inputImage = ciImage
            if let mask = filter.outputImage {
                let output = CoreMLHelper.blendImages(foreground: ciImage, mask: mask, isRedMask: true)
                return output
            }
            return nil
        }
    }
    
    static func peopleSegmentation(request: VNGeneratePersonSegmentationRequest) -> ImageProcessingHandler {
        return { ciImage in
            guard let ciImage = ciImage, let pixelBuffer = ciImage.pixelBuffer else { return nil }
            do {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
                try handler.perform([request])
                
                guard let mask = request.results?.first?.pixelBuffer else { return nil }
                let maskImage = CIImage(cvPixelBuffer: mask)
                let resultImage = blendImages(foreground: ciImage, mask: maskImage)
                return resultImage
            } catch let error {
                print(error)
            }
            return nil
        }
    }

    static func blendImages(
        background: CIImage = .clear,
        foreground: CIImage,
        mask: CIImage,
        isRedMask: Bool = false
    ) -> CIImage? {
        // 1
        let maskScaleX = foreground.extent.width / mask.extent.width
        let maskScaleY = foreground.extent.height / mask.extent.height
        let maskScaled = mask.transformed(
            by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))

        // 2
        let backgroundScaleX = (foreground.extent.width / background.extent.width)
        let backgroundScaleY = (foreground.extent.height / background.extent.height)
        // 3
        let blendFilter = isRedMask ? CIFilter.blendWithRedMask() : CIFilter.blendWithMask()
        let transparentBackground = background.cropped(to: foreground.extent)
        blendFilter.inputImage = foreground
        blendFilter.maskImage = maskScaled
        blendFilter.backgroundImage = transparentBackground
        let image = blendFilter.outputImage
        return image
    }
}
