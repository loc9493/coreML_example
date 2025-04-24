//
//  CameraView.swift
//  SegmentPeople
//
//  Created by NguyenLoc on 4/24/25.
//

import SwiftUI

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
                        let result = CIFilterHelper().getAllCIFilters()
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

#Preview {
    CameraView()
}
