import CoreImage
import CoreImage.CIFilterBuiltins

func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
    let filter = CIFilter.blendWithMask()
    
    filter.inputImage = image
    filter.maskImage = mask
    filter.backgroundImage = CIImage.empty()
    
    return filter.outputImage!
}
