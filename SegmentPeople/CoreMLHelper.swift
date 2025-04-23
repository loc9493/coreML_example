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
struct CoreMLHelper {
    static func peopleSegmentation(filter: CIPersonSegmentation) -> ImageProcessingHandler {
        return { ciImage in
            guard let ciImage = ciImage else { return nil }
            let context = CIContext(options: nil)
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
