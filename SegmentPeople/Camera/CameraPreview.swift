//
//  CameraPreview.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/24/25.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let showPreview: Bool
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        if showPreview {
            view.layer.addSublayer(previewLayer)            
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    CameraPreview(session: .init(), showPreview: false)
}
