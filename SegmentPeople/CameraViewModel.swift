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
    let personSegmentFilter = CIFilter.personSegmentation()
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
            }
        } catch {
            self.error = error
        }
    }
    
    func startSession() {
        personSegmentFilter.qualityLevel = 1
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
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
//        let output = CoreMLHelper.peopleSegmentation(filter: personSegmentFilter)(ciImage)
//        let output = CoreMLHelper.peopleSegmentation(request: personSegmentationRequest)(ciImage)
        let pipeline = CoreMLHelper.createProcessingPipeline(with: personSegmentationRequest)
        let output = pipeline.process(inputImage: ciImage)
        if let output, let cgImage = context.createCGImage(output, from: output.extent) {
            DispatchQueue.main.async {
                self.segmentationMask = cgImage
            }
        }
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
                VStack {
                    
                }
                HStack {
                    Button {
                        self.selectedImage = ranges.randomElement() ?? ""
                    } label: {
                        Text("Next")
                    }
                    
                    Button {
                        let result = CoreMLHelper.getAllCIFilters()
                        print(result)
                    } label: {
                        Text("Filters")
                    }
                    
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
