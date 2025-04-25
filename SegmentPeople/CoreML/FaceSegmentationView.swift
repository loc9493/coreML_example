//
//  FaceSegmentationView.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/25/25.
//

import SwiftUI
import Vision
import SceneKit

struct FaceSegmentationView: View {
    @StateObject var viewModel = CameraViewModel()
    let vnFaceRectRequest = VNDetectFaceRectanglesRequest()
    let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    @State var faceObservation: VNFaceObservation?
    @State private var headNode: SCNNode?
        @State private var sceneView = SCNView()
        @State private var scene = SCNScene()
    var body: some View {
        VStack {
            if viewModel.session.isRunning {
                CameraPreview(session: viewModel.session, showPreview: false)
                    .background(.green)
            }
        }
        .overlay(content: {
            faceLandmarkView
        })
        .onAppear {
            setupScene()
        }
        .task {
            viewModel.startSession()
            //            viewModel.addPeopleSegmentFilter()
            viewModel.pipeline?.addFilter({ input in
                do {
                    guard let input, let pixelBuffer = input.pixelBuffer else {
                        return input ?? .black
                    }
                    let handler = VNImageRequestHandler(
                        cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
                    try handler.perform([vnFaceRectRequest, faceLandmarksRequest])

                    guard let mask = vnFaceRectRequest.results?.first else { return .blue }
                    self.faceObservation = mask
                    guard let landmarks = faceLandmarksRequest.results?.first else { return .blue }
                    self.faceObservation = landmarks
                    return input
                } catch let error {
                    print(error)
                }
                return input
            })
        }
    }

    var faceLandmarkView: some View {
        ZStack {
            if let mask = viewModel.segmentationMask {
                Image(mask, scale: 1.0, label: Text("Segmentation Mask"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .border(.red, width: 1)
                    .overlay(alignment: .center) {
                        // Overlay for 3D head
                        FaceSceneKitView(scene: scene, headNode: $headNode, faceObservation: faceObservation)
                    }
                    .overlay {
                        if let face = faceObservation {
                            GeometryReader { proxy in
                                ZStack {
                                    // Face rectangle
                                    let width = face.boundingBox.width * proxy.size.width
                                    let height = face.boundingBox.height * proxy.size.height
                                    let x = face.boundingBox.minX * proxy.size.width + (width / 2)
                                    let y = (1 - face.boundingBox.minY - face.boundingBox.height) * proxy.size.height + (height / 2)

                                    Rectangle()
                                        .strokeBorder(Color.yellow, lineWidth: 3)
                                        .frame(width: width, height: height)
                                        .position(x: x, y: y)

                                    // Face landmarks
                                    if let landmarks = face.landmarks {
                                        // Draw eyes
                                        if let leftEye = landmarks.leftEye {
                                            FaceLandmarkView(
                                                points: leftEye.normalizedPoints,
                                                box: face.boundingBox,
                                                color: .green,
                                                proxy: proxy
                                            )
                                        }

                                        if let rightEye = landmarks.rightEye {
                                            FaceLandmarkView(
                                                points: rightEye.normalizedPoints,
                                                box: face.boundingBox,
                                                color: .green,
                                                proxy: proxy
                                            )
                                        }

                                        // Draw nose
                                        if let nose = landmarks.nose {
                                            FaceLandmarkView(
                                                points: nose.normalizedPoints,
                                                box: face.boundingBox,
                                                color: .blue,
                                                proxy: proxy
                                            )
                                        }

                                        // Draw mouth
                                        if let outerLips = landmarks.outerLips {
                                            FaceLandmarkView(
                                                points: outerLips.normalizedPoints,
                                                box: face.boundingBox,
                                                color: .red,
                                                proxy: proxy
                                            )
                                        }
                                        // Draw mouth
                                        if let outerLips = landmarks.leftEyebrow {
                                            FaceLandmarkView(
                                                points: outerLips.normalizedPoints,
                                                box: face.boundingBox,
                                                color: .brown,
                                                proxy: proxy
                                            )
                                        }
                                        if let outerLips = landmarks.rightEyebrow {
                                            FaceLandmarkView(
                                                points: outerLips.normalizedPoints,
                                                box: face.boundingBox,
                                                color: .brown,
                                                proxy: proxy
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
            }
        }
    }
    
    func setupScene() {
        // Configure scene
        scene.background.contents = UIColor.clear
        
        // Create camera
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Create 3D head model (simple example using a sphere)
        // In a real application, you'd load a more detailed 3D model
        let headGeometry = SCNSphere(radius: 0.5)
        headGeometry.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.7)
        
        let headNode = SCNNode(geometry: headGeometry)
        scene.rootNode.addChildNode(headNode)
        self.headNode = headNode
        
        // Add facial features (simple spheres for eyes, nose)
        let eyeGeometry = SCNSphere(radius: 0.1)
        eyeGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let leftEyeNode = SCNNode(geometry: eyeGeometry)
        leftEyeNode.position = SCNVector3(-0.2, 0.1, 0.4)
        headNode.addChildNode(leftEyeNode)
        
        let rightEyeNode = SCNNode(geometry: eyeGeometry)
        rightEyeNode.position = SCNVector3(0.2, 0.1, 0.4)
        headNode.addChildNode(rightEyeNode)
        
        let noseGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.05)
        noseGeometry.firstMaterial?.diffuse.contents = UIColor.red
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, -0.1, 0.4)
        headNode.addChildNode(noseNode)
    }
}

// Helper view to draw landmarks
struct FaceLandmarkView: View {
    let points: [CGPoint]
    let box: CGRect
    let color: Color
    let proxy: GeometryProxy

    var body: some View {
        Path { path in
            guard let firstPoint = points.first else { return }

            // Convert the first point from face coordinates to view coordinates
            let startX = (box.minX + firstPoint.x * box.width) * proxy.size.width
            let startY = (1 - (box.minY + firstPoint.y * box.height)) * proxy.size.height

            path.move(to: CGPoint(x: startX, y: startY))

            // Add lines to the rest of the points
            for point in points.dropFirst() {
                let x = (box.minX + point.x * box.width) * proxy.size.width
                let y = (1 - (box.minY + point.y * box.height)) * proxy.size.height
                path.addLine(to: CGPoint(x: x, y: y))
            }

            // Close the path if needed for certain features
            if color == .red || color == .green { // For lips and eyes
                path.closeSubpath()
            }
        }
        .stroke(color, lineWidth: 2)
    }
}

#Preview {
    FaceSegmentationView()
}
