//
//  CameraViewModel.swift
//  SegmentPeople
//
//  Created by Nguyen Loc on 21/4/25.
//

import SwiftUI
import AVFoundation
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isSessionRunning = false
    @Published var error: Error?
    @Published var segmentationMask: CGImage?
    
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var personSegmentationRequest: VNGeneratePersonSegmentationRequest?
    
    override init() {
        super.init()
        setupVision()
        setupSession()
    }
    
    private func setupVision() {
        personSegmentationRequest = VNGeneratePersonSegmentationRequest()
        personSegmentationRequest?.qualityLevel = .balanced
        personSegmentationRequest?.outputPixelFormat = kCVPixelFormatType_OneComponent8
    }
    
    private func setupSession() {
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            error = CameraError.noCameraAvailable
            return
        }
        
        let queue = DispatchQueue(label: "myqueue")
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        
        // Set video orientation
        videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                error = CameraError.cannotAddInput
                return
            }
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                // Configure video orientation after adding output
                if let connection = videoOutput.connection(with: .video) {
                    connection.videoOrientation = .portrait
                    connection.isVideoMirrored = true
                }
            } else {
                error = CameraError.cannotAddOutput
                return
            }
            
        } catch {
            self.error = error
            return
        }
    }
    
    func startSession() {
        guard !isSessionRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = self?.session.isRunning ?? false
            }
        }
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        
        session.stopRunning()
        isSessionRunning = false
    }
    
    enum CameraError: Error {
        case noCameraAvailable
        case cannotAddInput
        case cannotAddOutput
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let personSegmentationRequest else {
            return
        }
        
        let result = CoreMLHelper.peopleSegmentation(imageBuffer: pixelBuffer, request: personSegmentationRequest)
        let ciImage = CIImage(cvPixelBuffer: result)
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async {
                self.segmentationMask = cgImage
            }
        }
//
//        do {
//            guard let request = personSegmentationRequest else { return }
//            
//            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
//            try handler.perform([request])
//            
//            guard let mask = request.results?.first?.pixelBuffer else { return }
//
//            // Convert mask to CGImage for display
//            let ciImage = CIImage(cvPixelBuffer: mask)
//            let orgFrame = CIImage(cvPixelBuffer: pixelBuffer)
//            let context = CIContext(options: nil)
//            
//            
//            
//            
//            // scale mask
//             let maskScaleX = orgFrame.extent.width / ciImage.extent.width
//             let maskScaleY = orgFrame.extent.height / ciImage.extent.height
//             let maskScaled = ciImage.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))
//
//            let resultImage = applyMask(mask: maskScaled, to: orgFrame)
//
//            if let cgImage = context.createCGImage(resultImage, from: resultImage.extent) {
//                DispatchQueue.main.async {
//                    self.segmentationMask = cgImage
//                }
//            }
//            
//        } catch {
//            print("Error performing person segmentation: \(error)")
//        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
//        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct CameraView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    let ranges = (1...9).map { "IMG\($0)" }
    @State var selectedImage = "IMG8"
    var body: some View {
        VStack {
            ZStack {
                if cameraViewModel.isSessionRunning {
                    CameraPreview(session: cameraViewModel.session)
                }
                
                if let error = cameraViewModel.error {
                    Text("Camera Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .padding()
                }
                Button {
                    self.selectedImage = ranges.randomElement() ?? ""
                } label: {
                    Text("Next")
                }

            }
            .frame(maxWidth: .infinity, minHeight: 300)
            AdvancedDraggableResizableView {
                ZStack {
                    Image(selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    VStack {
                        if let mask = cameraViewModel.segmentationMask {
                            Image(mask, scale: 1.0, label: Text("Segmentation Mask"))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .border(.red, width: 1)
                        }
                    }
                }
            }
        }
        .onAppear {
            cameraViewModel.startSession()
        }
        .onDisappear {
            cameraViewModel.stopSession()
        }
    }
}
