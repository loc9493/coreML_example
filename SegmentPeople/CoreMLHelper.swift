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
    static func peopleSegmentation(imageBuffer: CVImageBuffer, request: VNGeneratePersonSegmentationRequest) -> CVImageBuffer {
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
            try handler.perform([request])
            
            guard let mask = request.results?.first?.pixelBuffer else { return imageBuffer }
            
            // Convert mask to CGImage for display
            let ciImage = CIImage(cvPixelBuffer: mask)
            let orgFrame = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext(options: nil)
            // scale mask
            let maskScaleX = orgFrame.extent.width / ciImage.extent.width
            let maskScaleY = orgFrame.extent.height / ciImage.extent.height
            let maskScaled = ciImage.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))
            
            let resultImage = applyMask(mask: maskScaled, to: orgFrame)
            return resultImage.pixelBuffer ?? imageBuffer
        } catch let error {
            print(error)
        }
        return imageBuffer
    }
    static func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = image
        blendFilter.backgroundImage = CIImage(color: .clear)
        blendFilter.maskImage = mask
        return blendFilter.outputImage ?? image
    }
}
