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
    let ranges = (1...9).map { "IMG\($0)" }
    @Published var selectedImage = "IMG8"
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let personSegmentFilter = CIFilter.personSegmentation()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var personSegmentationRequest: VNGeneratePersonSegmentationRequest?
    @Published var pipeline: ImageFilterPipeline? = nil
    override init() {
        super.init()
        setupVision()
        setupSession()
    }
    
    private func setupVision() {
        personSegmentationRequest = VNGeneratePersonSegmentationRequest()
        personSegmentationRequest?.qualityLevel = .balanced
        personSegmentationRequest?.outputPixelFormat = kCVPixelFormatType_OneComponent8
        pipeline = CoreMLHelper.createProcessingPipeline(with: personSegmentationRequest!)
    }
    
    func addPeopleSegmentFilter() {
        pipeline?.addFilter(CoreMLHelper.peopleSegmentation(request: personSegmentationRequest!))
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
        let output = pipeline?.process(inputImage: ciImage)
        if let output, let cgImage = context.createCGImage(output, from: output.extent) {
            DispatchQueue.main.async {
                self.segmentationMask = cgImage
            }
        }
    }
}
