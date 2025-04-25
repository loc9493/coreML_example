import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct SwipeTransitionView: View {
    let fromImage: UIImage
    let toImage: UIImage
    @State private var progress: Double = 0.0
    @State private var angle: Double = 0.0 // Angle in degrees
    @State private var width: Double = 80.0 // Width of the transition
    
    var body: some View {
        VStack {
            // Display the transition image
            if let processedImage = createSwipeTransition() {
                Image(uiImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Failed to create transition")
            }
            
            // Controls
            VStack {
                Text("Progress: \(progress, specifier: "%.2f")")
                Slider(value: $progress, in: 0...1)
                
                Text("Angle: \(angle, specifier: "%.0f")°")
                Slider(value: $angle, in: 0...360)
                
                Text("Width: \(width, specifier: "%.0f")")
                Slider(value: $width, in: 10...200)
                
                Button("Animate Transition") {
                    // Reset progress
                    progress = 0
                    
                    // Animate over 1.5 seconds
                    withAnimation(.easeInOut(duration: 1.5)) {
                        progress = 1.0
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    func createSwipeTransition() -> UIImage? {
        // Convert UIImages to CIImages
        guard let fromCIImage = CIImage(image: fromImage),
              let toCIImage = CIImage(image: toImage) else {
            return nil
        }
        
        // Create the swipe transition filter
        let filter = CIFilter.swipeTransition()
        
        // Set the input parameters
        filter.inputImage = fromCIImage
        filter.targetImage = toCIImage
        filter.time = Float(progress)
        filter.angle = Float(angle * .pi / 180) // Convert degrees to radians
        filter.width = Float(width)
        
        // Optional: You can also set opacity
        // filter.opacity = 1.0
        
        // Get the output image
        guard let outputCIImage = filter.outputImage else {
            return nil
        }
        
        // Convert CIImage back to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// Preview
struct SwipeTransitionView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeTransitionView(
            fromImage: UIImage(named: "IMG1")!,
            toImage: UIImage(named: "IMG2")!
        )
    }
}
