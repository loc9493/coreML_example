//
//  FaceSceneKitView.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/25/25.
//

import SwiftUI
import SceneKit
import Vision

// SceneKit wrapper for SwiftUI
struct FaceSceneKitView: UIViewRepresentable {
    var scene: SCNScene
    @Binding var headNode: SCNNode?
    var faceObservation: VNFaceObservation?
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.allowsCameraControl = false
        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the 3D head position based on face detection
        if let face = faceObservation, let head = headNode {
            // Calculate face center in normalized coordinates (0-1)
            let faceCenterX = face.boundingBox.midX
            let faceCenterY = face.boundingBox.midY
            
            // Convert to SceneKit coordinates (-1 to 1)
            let sceneX = (faceCenterX * 2) - 1
            let sceneY = -((faceCenterY * 2) - 1) // Flip Y axis
            
            // Update position
            head.position = SCNVector3(sceneX * 2, sceneY * 2, 0)
            
            // Scale based on face size
            let scale = Float(face.boundingBox.width * 4)
            head.scale = SCNVector3(scale, scale, scale)
            
            // Add some rotation based on face position for a more dynamic effect
            if let landmarks = face.landmarks {
                // If we have landmarks, we can attempt to calculate face orientation
                if let leftEye = landmarks.leftEye?.normalizedPoints.first,
                   let rightEye = landmarks.rightEye?.normalizedPoints.first {
                    
                    // Calculate roll angle from eyes
                    let deltaY = rightEye.y - leftEye.y
                    let deltaX = rightEye.x - leftEye.x
                    let rollAngle = atan2(deltaY, deltaX)
                    
                    head.eulerAngles.z = Float(rollAngle)
                }
            }
        }
    }
}
