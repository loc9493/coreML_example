//
//  CIFilterHelper.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/24/25.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

struct FilterItem: Equatable {
    var filterName: String
    var filterNameType: String
}

enum CIFilterValueHelper {
    case filter
    func randomValueForCIAttribute(_ attribute: [String: Any]) -> Any {
        // Extract the attribute class
        guard let attributeClass = attribute["CIAttributeClass"] as? String else {
            return NSNull()
        }
        
        switch attributeClass {
        case "NSNumber":
            return randomNumberValue(for: attribute)
        case "CIVector":
            return randomVectorValue(for: attribute)
        case "CIColor":
            return randomColorValue()
        case "NSValue": // For transforms
            return randomTransformValue()
        case "NSString":
            return randomStringValue(for: attribute)
        case "NSData":
            return randomDataValue()
        default:
            return NSNull()
        }
    }

    func randomNumberValue(for attribute: [String: Any]) -> NSNumber {
        let type = attribute["CIAttributeType"] as? String ?? "CIAttributeTypeScalar"
        
        // Get min/max constraints
        let minValue = (attribute["CIAttributeMin"] as? NSNumber)?.doubleValue ?? 0.0
        let maxValue = (attribute["CIAttributeMax"] as? NSNumber)?.doubleValue ?? 1.0
        
        // Use slider values if available for better ranges
        let sliderMin = (attribute["CIAttributeSliderMin"] as? NSNumber)?.doubleValue ?? minValue
        let sliderMax = (attribute["CIAttributeSliderMax"] as? NSNumber)?.doubleValue ?? maxValue
        
        // Generate random value
        let randomValue = Double.random(in: sliderMin...sliderMax)
        
        // Handle specific types
        switch type {
        case "CIAttributeTypeBoolean":
            return NSNumber(value: Bool.random())
        case "CIAttributeTypeInteger", "CIAttributeTypeCount":
            return NSNumber(value: Int(randomValue))
        case "CIAttributeTypeAngle":
            return NSNumber(value: randomValue) // Angles in radians
        case "CIAttributeTypeDistance":
            return NSNumber(value: max(0, randomValue)) // Distances typically positive
        case "CIAttributeTypeTime":
            return NSNumber(value: min(1, max(0, randomValue))) // Time usually 0-1
        default:
            return NSNumber(value: randomValue)
        }
    }

    func randomVectorValue(for attribute: [String: Any]) -> CIVector {
        let type = attribute["CIAttributeType"] as? String ?? ""
        
        switch type {
        case "CIAttributeTypePosition":
            return CIVector(x: CGFloat.random(in: 0...300), y: CGFloat.random(in: 0...300))
        case "CIAttributeTypeRectangle":
            return CIVector(x: CGFloat.random(in: 0...100),
                           y: CGFloat.random(in: 0...100),
                           z: CGFloat.random(in: 50...300),
                           w: CGFloat.random(in: 50...300))
        case "CIAttributeTypePosition3":
            return CIVector(x: CGFloat.random(in: 0...300),
                           y: CGFloat.random(in: 0...300),
                           z: CGFloat.random(in: 0...300))
        case "CIAttributeTypeOffset":
            return CIVector(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -50...50))
        default:
            // Default to a 2D position
            return CIVector(x: CGFloat.random(in: 0...300), y: CGFloat.random(in: 0...300))
        }
    }

    func randomColorValue() -> CIColor {
        return CIColor(red: CGFloat.random(in: 0...1),
                      green: CGFloat.random(in: 0...1),
                       blue: CGFloat.random(in: 0...1),
                      alpha: 1.0)
    }

    func randomTransformValue() -> NSValue {
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: CGFloat.random(in: -50...50),
                                          y: CGFloat.random(in: -50...50))
        transform = transform.rotated(by: CGFloat.random(in: 0...CGFloat.pi*2))
        transform = transform.scaledBy(x: CGFloat.random(in: 0.5...1.5),
                                      y: CGFloat.random(in: 0.5...1.5))
        
        return NSValue(cgAffineTransform: transform)
    }

    func randomStringValue(for attribute: [String: Any]) -> String {
        let displayName = attribute["CIAttributeDisplayName"] as? String ?? ""
        
        if displayName.lowercased().contains("font") {
            return ["Helvetica", "Arial", "Times New Roman", "Courier", "Verdana"].randomElement()!
        } else {
            let length = Int.random(in: 5...10)
            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return String((0..<length).map { _ in letters.randomElement()! })
        }
    }

    func randomDataValue() -> NSData {
        let length = Int.random(in: 16...128)
        var bytes = [UInt8](repeating: 0, count: length)
        for i in 0..<length {
            bytes[i] = UInt8.random(in: 0...255)
        }
        return NSData(bytes: bytes, length: length)
    }

    // Function to generate random values for all attributes of a filter
    func randomValuesForFilter(_ filter: CIFilter) -> [String: Any] {
        var randomValues = [String: Any]()
        
        // Process each input attribute
        for (key, value) in filter.attributes where key.hasPrefix("input") {
            // Skip image inputs as they should be provided separately
            if let attrDict = value as? [String: Any],
               let attrClass = attrDict["CIAttributeClass"] as? String,
               attrClass == "CIImage" {
                continue
            }
            
            if let attrDict = value as? [String: Any] {
                let randomValue = randomValueForCIAttribute(attrDict)
                if !(randomValue is NSNull) {
                    randomValues[key] = randomValue
                }
            }
        }
        
        return randomValues
    }

    // Example usage:
    // let filter = CIFilter(name: "CIBloom")!
    // let randomValues = randomValuesForFilter("CIBloom")
    // for (key, value) in randomValues {
    //     filter.setValue(value, forKey: key)
    // }
}
struct CIFilterHelper {
    func getAllCIFilters() -> [FilterItem] {
        // Get all filter names
        let filterNames = CIFilter.filterNames(inCategory: nil)
        var result = [FilterItem]()
        filterNames.forEach { filterName in
            if let filter = filterName.getCIFilter(), let displayName = filter.attributes["CIAttributeFilterDisplayName"] as? String {
                let filterItem = FilterItem.init(filterName: displayName, filterNameType: filter.name)
                result.append(filterItem)
            }
        }
        return result
    }
}

extension String {
    func getCIFilter() -> CIFilter? {
        return CIFilter(name: self)
    }
}

extension CIFilter {
    /// Generate random values for common filter input parameters
    static func fillFilterWithRandomValues(_ filter: CIFilter) {
        // Get input keys for the filter
        let inputKeys = filter.inputKeys
        
        for key in inputKeys {
            switch key {
            case kCIInputImageKey, "inputImage":
                // Skip image inputs - these would be set by the application
                continue
                
            case "inputCenter", "center":
                filter.setValue(CIVector(x: CGFloat.random(in: 0...300), y: CGFloat.random(in: 0...300)), forKey: key)
                
            case "inputColor", "color", "inputColor0", "color0", "inputColor1", "color1":
                filter.setValue(CIColor(
                    red: CGFloat.random(in: 0...1),
                    green: CGFloat.random(in: 0...1),
                    blue: CGFloat.random(in: 0...1),
                    alpha: 1.0
                ), forKey: key)
                
            case "inputRadius", "radius":
                filter.setValue(Float.random(in: 1...100), forKey: key)
                
            case "inputAngle", "angle":
                filter.setValue(Float.random(in: 0...Float.pi * 2), forKey: key)
                
            case "inputIntensity", "intensity":
                filter.setValue(Float.random(in: 0...1), forKey: key)
                
            case "inputScale", "scale":
                filter.setValue(Float.random(in: 0...10), forKey: key)
                
            case "inputWidth", "width":
                filter.setValue(Float.random(in: 1...100), forKey: key)
                
            case "inputHeight", "height":
                filter.setValue(Float.random(in: 1...100), forKey: key)
                
            case "inputAmount", "amount":
                filter.setValue(Float.random(in: 0...1), forKey: key)
                
            case "inputTime", "time":
                filter.setValue(Float.random(in: 0...1), forKey: key)
                
            case "inputSharpness", "sharpness":
                filter.setValue(Float.random(in: 0...1), forKey: key)
                
            case "inputPoint0", "point0":
                filter.setValue(CIVector(x: CGFloat.random(in: 0...150), y: CGFloat.random(in: 0...150)), forKey: key)
                
            case "inputPoint1", "point1":
                filter.setValue(CIVector(x: CGFloat.random(in: 150...300), y: CGFloat.random(in: 150...300)), forKey: key)
                
            default:
                // For other parameters, we could try to determine type and set values
                // but would require more complex reflection
                continue
            }
        }
    }
}
